/** @jsxImportSource @opentui/solid */

import { Plugin } from "@opencode/plugin/tui"
import { createMemo, createSignal, For, onCleanup, onMount, Show } from "solid-js"
import { cpus, freemem, hostname, totalmem } from "node:os"
import { StatusSidebarRpc } from "./rpc.js"

const BAR_WIDTH = 9
const SAMPLE_MS = 30_000
const TEXT_MAX = 36

type UsageMetric = { label: string; percent?: number; value?: string; resetAt?: number }
type UsageProvider = { id: string; name: string; auth: string; metrics: UsageMetric[] }
type Section = "speed" | "usage" | "resources" | "last"

function clamp(value: number): number {
  return Math.max(0, Math.min(100, Math.round(value)))
}

export function bar(value: number): string {
  const filled = Math.round((clamp(value) / 100) * BAR_WIDTH)
  return "█".repeat(filled) + "░".repeat(BAR_WIDTH - filled)
}

function truncate(value: string, max = TEXT_MAX): string {
  const text = value.replace(/\s+/g, " ").trim()
  return text.length <= max ? text : `${text.slice(0, max - 1)}…`
}

function duration(ms: number): string | undefined {
  if (!Number.isFinite(ms) || ms <= 0) return undefined
  const seconds = Math.floor(ms / 1_000)
  const days = Math.floor(seconds / 86_400)
  const hours = Math.floor((seconds % 86_400) / 3_600)
  const minutes = Math.floor((seconds % 3_600) / 60)
  if (days) return `${days}d${hours}h`
  if (hours) return `${hours}h${minutes}m`
  return `${Math.max(1, minutes)}m`
}

function sampleCpu(previous?: { idle: number; total: number }) {
  let idle = 0
  let total = 0
  for (const cpu of cpus()) {
    idle += cpu.times.idle
    total += cpu.times.idle + cpu.times.user + cpu.times.nice + cpu.times.sys + cpu.times.irq
  }
  const current = { idle, total }
  if (!previous || total <= previous.total) return { current, percent: undefined }
  const used = 1 - (idle - previous.idle) / (total - previous.total)
  return { current, percent: clamp(used * 100) }
}

function ram(): number | undefined {
  const total = totalmem()
  return total > 0 ? clamp(((total - freemem()) / total) * 100) : undefined
}

function title(name: string, expanded: boolean): string {
  return `${expanded ? "▼" : "▶"} ${name}`
}

function Sidebar(props: { context: Plugin.Context; sessionID: string }) {
  const theme = props.context.theme
  const usageClient = props.context.client.rpc(StatusSidebarRpc)
  const [collapsed, setCollapsed] = createSignal(new Set<Section>())
  const [closedProviders, setClosedProviders] = createSignal(new Set<string>())
  const [usage, setUsage] = createSignal<UsageProvider[]>([])
  const [cpu, setCpu] = createSignal<number | undefined>()
  const [memory, setMemory] = createSignal<number | undefined>(ram())
  const [now, setNow] = createSignal(Date.now())
  let baseline: { idle: number; total: number } | undefined

  const messages = createMemo(() => props.context.data.session.message.list(props.sessionID))
  const speed = createMemo(() => {
    let tokens = 0
    let elapsed = 0
    let last: number | undefined
    for (const message of messages()) {
      if (message.type !== "assistant" || !message.tokens) continue
      const ended = message.time.streamed ?? message.time.completed
      if (!ended || ended <= message.time.created) continue
      const output = message.tokens.output + message.tokens.reasoning
      if (output <= 0) continue
      const seconds = (ended - message.time.created) / 1_000
      tokens += output
      elapsed += seconds
      last = Math.round(output / seconds)
    }
    return { average: elapsed > 0 ? Math.round(tokens / elapsed) : undefined, last }
  })
  const lastMessage = createMemo(() => {
    const list = messages()
    for (let index = list.length - 1; index >= 0; index -= 1) {
      const message = list[index]
      if (message.type === "user" && message.text.trim()) return message.text
    }
    return undefined
  })

  const expanded = (section: Section) => !collapsed().has(section)
  const toggle = (section: Section) => {
    const next = new Set(collapsed())
    next.has(section) ? next.delete(section) : next.add(section)
    setCollapsed(next)
  }
  const toggleProvider = (id: string) => {
    const next = new Set(closedProviders())
    next.has(id) ? next.delete(id) : next.add(id)
    setClosedProviders(next)
  }
  const refreshHost = () => {
    const sampled = sampleCpu(baseline)
    baseline = sampled.current
    setCpu(sampled.percent)
    setMemory(ram())
    setNow(Date.now())
  }
  const refreshUsage = () => {
    void usageClient
      .usage({})
      .then((result) => setUsage((result as { providers: UsageProvider[] }).providers))
      .catch(() => setUsage([]))
  }

  onMount(() => {
    refreshHost()
    refreshUsage()
    const first = setTimeout(refreshHost, 1_000)
    const timer = setInterval(() => {
      refreshHost()
      refreshUsage()
    }, SAMPLE_MS)
    onCleanup(() => {
      clearTimeout(first)
      clearInterval(timer)
    })
  })

  const host = (() => {
    try {
      return hostname().trim() || undefined
    } catch {
      return undefined
    }
  })()
  const showSpeed = () => speed().average !== undefined || speed().last !== undefined
  const showResources = () => cpu() !== undefined || memory() !== undefined
  const reset = (metric: UsageMetric) =>
    metric.resetAt === undefined ? undefined : duration(metric.resetAt - now())
  const meter = (value: number) => `[ ${bar(value)} ]`

  return (
    <box flexDirection="column" gap={1}>
      <Show when={host}>
        <text fg={theme.text.base}>
          <b>{`HOST · ${truncate(host!, 24)}`}</b>
        </text>
      </Show>

      <Show when={showSpeed()}>
        <box flexDirection="column">
          <box onMouseDown={() => toggle("speed")}>
            <text fg={theme.text.base}>
              <b>{title("The Model Speed:", expanded("speed"))}</b>
            </text>
          </box>
          <Show when={expanded("speed") && speed().average !== undefined}>
            <text fg={theme.text.muted}>{`  ${meter(speed().average!)} ${speed().average} tok/s · session`}</text>
          </Show>
          <Show when={expanded("speed") && speed().last !== undefined}>
            <text fg={theme.text.muted}>{`  ${meter(speed().last!)} ${speed().last} tok/s · last`}</text>
          </Show>
        </box>
      </Show>

      <Show when={usage().length > 0}>
        <box flexDirection="column">
          <box onMouseDown={() => toggle("usage")}>
            <text fg={theme.text.base}>
              <b>{title("THE USAGE", expanded("usage"))}</b>
            </text>
          </box>
          <Show when={expanded("usage")}>
            <For each={usage()}>
              {(provider) => {
                const open = () => !closedProviders().has(provider.id)
                return (
                  <box flexDirection="column">
                    <box onMouseDown={() => toggleProvider(provider.id)}>
                      <text fg={theme.text.base}>{`  ${truncate(`${provider.name} · ${provider.auth}`, 29)} ${open() ? "▾" : "▸"}`}</text>
                    </box>
                    <Show when={open()}>
                      <For each={provider.metrics}>
                        {(metric) => (
                          <box flexDirection="column">
                            <text>
                              <span fg={theme.text.muted}>{`    ${truncate(metric.label, 8).padEnd(9)}`}</span>
                              <Show when={metric.percent !== undefined}>
                                <span
                                  fg={
                                    metric.percent! < 20
                                      ? theme.text.feedback.error.base
                                      : metric.percent! <= 50
                                        ? theme.text.feedback.warning.base
                                        : theme.text.base
                                  }
                                >
                                  {`${meter(metric.percent!)} ${metric.percent}%`}
                                </span>
                              </Show>
                              <Show when={metric.percent === undefined && metric.value}>
                                <span fg={theme.text.base}>{metric.value}</span>
                              </Show>
                            </text>
                            <Show when={reset(metric)}>
                              <text fg={theme.text.muted}>{`              ↻ ${reset(metric)}`}</text>
                            </Show>
                          </box>
                        )}
                      </For>
                    </Show>
                  </box>
                )
              }}
            </For>
          </Show>
        </box>
      </Show>

      <Show when={showResources()}>
        <box flexDirection="column">
          <box onMouseDown={() => toggle("resources")}>
            <text fg={theme.text.base}>
              <b>{title("CPU & RAM", expanded("resources"))}</b>
            </text>
          </box>
          <Show when={expanded("resources") && memory() !== undefined}>
            <text fg={theme.text.muted}>{`  RAM ${meter(memory()!)} ${memory()}%`}</text>
          </Show>
          <Show when={expanded("resources") && cpu() !== undefined}>
            <text fg={theme.text.muted}>{`  CPU ${meter(cpu()!)} ${cpu()}%`}</text>
          </Show>
        </box>
      </Show>

      <Show when={lastMessage()}>
        <box flexDirection="column">
          <box onMouseDown={() => toggle("last")}>
            <text fg={theme.text.base}>
              <b>{title("Last Message", expanded("last"))}</b>
            </text>
          </box>
          <Show when={expanded("last")}>
            <text fg={theme.text.muted}>{`  ${truncate(lastMessage()!)}`}</text>
          </Show>
        </box>
      </Show>
    </box>
  )
}

export default Plugin.define({
  id: "status-sidebar.tui",
  setup(context) {
    return context.ui.slot({
      append: "sidebar.content",
      render: ({ sessionID }) => <Sidebar context={context} sessionID={sessionID} />,
    })
  },
})
