import { Plugin } from "@opencode/plugin"
import { StatusSidebarRpc } from "./rpc.js"

const OPENAI_ENDPOINT = "https://chatgpt.com/backend-api/wham/usage"
const DEEPSEEK_ENDPOINT = "https://api.deepseek.com/user/balance"
const TIMEOUT_MS = 5_000
const MAX_RESPONSE_BYTES = 256 * 1024
const SUCCESS_TTL_MS = 5 * 60 * 1_000
const FAILURE_TTL_MS = 45 * 1_000

type UsageMetric = {
  label: string
  percent?: number
  value?: string
  resetAt?: number
}

type UsageOutput = {
  providers: Array<{
    id: string
    name: string
    auth: string
    metrics: UsageMetric[]
  }>
}

type OpenAICredential = {
  type: "oauth"
  access: string
  expires: number
  metadata?: Record<string, unknown>
}

type KeyCredential = {
  type: "key"
  key: string
}

class UsageError extends Error {}

function percent(value: number): number {
  return Math.max(0, Math.min(100, Math.round(value)))
}

function labelForWindow(seconds: unknown): string {
  if (seconds === 18_000) return "5h"
  if (seconds === 604_800) return "Weekly"
  if (seconds === 2_592_000 || seconds === 2_628_000) return "Monthly"
  if (typeof seconds !== "number" || !Number.isFinite(seconds) || seconds <= 0) return "Window"
  if (seconds >= 86_400) return `${Math.round(seconds / 86_400)}d`
  if (seconds >= 3_600) return `${Math.round(seconds / 3_600)}h`
  return `${Math.max(1, Math.round(seconds / 60))}m`
}

function resetAt(window: Record<string, unknown>): number | undefined {
  if (typeof window.reset_after_seconds === "number" && Number.isFinite(window.reset_after_seconds)) {
    return Date.now() + Math.max(0, window.reset_after_seconds) * 1_000
  }
  if (typeof window.reset_at !== "number" || !Number.isFinite(window.reset_at)) return undefined
  return window.reset_at > 10_000_000_000 ? window.reset_at : window.reset_at * 1_000
}

function money(value: unknown): string | undefined {
  if (typeof value !== "number" && typeof value !== "string") return undefined
  const raw = String(value).trim()
  if (!/^-?\d+(?:\.\d+)?$/.test(raw)) return undefined
  const parsed = Number(raw)
  return Number.isFinite(parsed) ? parsed.toFixed(2) : undefined
}

async function fetchJson(
  url: typeof OPENAI_ENDPOINT | typeof DEEPSEEK_ENDPOINT,
  headers: Record<string, string>,
  signal: AbortSignal,
): Promise<Record<string, unknown>> {
  const controller = new AbortController()
  const stop = () => controller.abort()
  signal.addEventListener("abort", stop, { once: true })
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS)
  try {
    const response = await fetch(url, {
      method: "GET",
      headers: { ...headers, Accept: "application/json" },
      redirect: "error",
      signal: controller.signal,
    })
    if (!response.ok) throw new UsageError("request failed")
    if (!(response.headers.get("content-type") ?? "").toLowerCase().includes("json")) {
      throw new UsageError("invalid response")
    }
    const declared = Number(response.headers.get("content-length"))
    if (Number.isFinite(declared) && declared > MAX_RESPONSE_BYTES) throw new UsageError("response too large")
    if (!response.body) throw new UsageError("invalid response")

    const reader = response.body.getReader()
    const decoder = new TextDecoder()
    let size = 0
    let text = ""
    while (true) {
      const chunk = await reader.read()
      if (chunk.done) break
      size += chunk.value.byteLength
      if (size > MAX_RESPONSE_BYTES) {
        await reader.cancel()
        throw new UsageError("response too large")
      }
      text += decoder.decode(chunk.value, { stream: true })
    }
    text += decoder.decode()
    const value: unknown = JSON.parse(text)
    if (!value || typeof value !== "object" || Array.isArray(value)) throw new UsageError("invalid response")
    return value as Record<string, unknown>
  } catch {
    throw new UsageError("request failed")
  } finally {
    clearTimeout(timer)
    signal.removeEventListener("abort", stop)
  }
}

function parseUsage(body: Record<string, unknown>): UsageMetric[] {
  const rate = body.rate_limit
  const credits = body.credits
  const metrics: UsageMetric[] = []
  if (rate && typeof rate === "object" && !Array.isArray(rate)) {
    for (const key of ["primary_window", "secondary_window"]) {
      const candidate = (rate as Record<string, unknown>)[key]
      if (!candidate || typeof candidate !== "object" || Array.isArray(candidate)) continue
      const window = candidate as Record<string, unknown>
      if (typeof window.used_percent !== "number" || !Number.isFinite(window.used_percent)) continue
      metrics.push({
        label: labelForWindow(window.limit_window_seconds),
        percent: percent(100 - window.used_percent),
        resetAt: resetAt(window),
      })
    }
  }
  if (credits && typeof credits === "object" && !Array.isArray(credits)) {
    const value = credits as Record<string, unknown>
    const balance = money(value.balance)
    if (value.has_credits === true && value.unlimited !== true && balance !== undefined) {
      metrics.push({ label: "Credits", value: `${balance} credits` })
    }
  }
  return metrics
}

function parseDeepSeekBalance(body: Record<string, unknown>): UsageMetric[] {
  if (!Array.isArray(body.balance_infos)) throw new UsageError("invalid response")
  const metrics: UsageMetric[] = []
  for (const item of body.balance_infos) {
    if (!item || typeof item !== "object" || Array.isArray(item)) continue
    const info = item as Record<string, unknown>
    if (info.currency !== "CNY" && info.currency !== "USD") continue
    const amount = money(info.total_balance)
    if (amount !== undefined) metrics.push({ label: `Balance · ${info.currency}`, value: amount })
  }
  return metrics
}

export default Plugin.define({
  id: "status-sidebar.server",
  async setup(context) {
    let cached: { value: UsageOutput; until: number } | undefined
    let inflight: Promise<UsageOutput> | undefined

    const load = async (signal: AbortSignal): Promise<UsageOutput> => {
      const now = Date.now()
      if (cached && cached.until > now) return cached.value
      if (inflight) return inflight

      inflight = (async () => {
        const empty: UsageOutput = { providers: [] }
        const providers: UsageOutput["providers"] = []
        try {
          const connection = await context.integration.connection.active("openai")
          if (connection?.type === "credential" && connection.method === "oauth") {
            const resolved = await context.integration.connection.resolve(connection)
            if (resolved?.type === "oauth") {
              const credential = resolved as OpenAICredential
              if (credential.access && credential.expires > Date.now()) {
                const accountID = credential.metadata?.accountID
                const body = await fetchJson(
                  OPENAI_ENDPOINT,
                  {
                    Authorization: `Bearer ${credential.access}`,
                    ...(typeof accountID === "string" ? { "ChatGPT-Account-Id": accountID } : {}),
                    "User-Agent": "opencode-status-sidebar/2",
                  },
                  signal,
                )
                const metrics = parseUsage(body)
                if (metrics.length) providers.push({ id: "openai", name: "OpenAI", auth: "Subscription", metrics })
              }
            }
          }
        } catch {}

        try {
          const connection = await context.integration.connection.active("deepseek")
          if (connection?.type === "credential" && connection.method === "key") {
            const resolved = await context.integration.connection.resolve(connection)
            if (resolved?.type === "key") {
              const credential = resolved as KeyCredential
              if (credential.key) {
                const body = await fetchJson(
                  DEEPSEEK_ENDPOINT,
                  { Authorization: `Bearer ${credential.key}` },
                  signal,
                )
                const metrics = parseDeepSeekBalance(body)
                if (metrics.length) providers.push({ id: "deepseek", name: "DeepSeek", auth: "API", metrics })
              }
            }
          }
        } catch {}

        return providers.length ? { providers } : empty
      })()

      try {
        const value = await inflight
        cached = { value, until: Date.now() + (value.providers.length ? SUCCESS_TTL_MS : FAILURE_TTL_MS) }
        return value
      } finally {
        inflight = undefined
      }
    }

    await context.rpc.register(StatusSidebarRpc, {
      usage: async (_input, rpcContext) => load(rpcContext.signal),
    })
  },
})
