import { cpus, freemem, totalmem } from "node:os";
import { basename, dirname, parse } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

// Unicode 品牌近似标识，不依赖 Nerd Font；未知 provider 显示名称。
function providerMark(provider: string): string {
  if (provider === "openai" || provider.startsWith("openai-")) return "◎";
  if (provider === "anthropic") return "✳";
  if (provider === "google" || provider.startsWith("google-")) return "✦";
  if (provider === "deepseek") return "≈";
  return provider ? `[${clean(provider)}]` : "◇";
}

// 路径和模型名称只能作为文本显示，不能注入控制序列或换行。
function clean(text: string): string {
  return text.replace(/[\x00-\x1f\x7f-\x9f\u2028\u2029]/g, " ");
}

function shortPath(cwd: string, lastOnly = false): string {
  const leaf = basename(cwd);
  if (!leaf) return parse(cwd).root || cwd;
  const parent = basename(dirname(cwd));
  return clean(lastOnly || !parent ? leaf : `${parent}/${leaf}`);
}

function cpuSnapshot(): { idle: number; total: number } | undefined {
  try {
    const cores = cpus();
    if (!cores.length) return undefined;
    let idle = 0;
    let total = 0;
    for (const cpu of cores) {
      idle += cpu.times.idle;
      total += Object.values(cpu.times).reduce((sum, time) => sum + time, 0);
    }
    return { idle, total };
  } catch {
    return undefined;
  }
}

function percent(value: number | null | undefined): string {
  return value == null || !Number.isFinite(value) ? "?" : `${Math.round(value)}%`;
}

function tokens(value: number | null | undefined): string {
  return value == null || !Number.isFinite(value) ? "?" : `${Number((value / 1_000).toFixed(1))}k`;
}

export default function (pi: ExtensionAPI) {
  let dispose = () => {};

  pi.on("session_start", (_event, ctx) => {
    dispose();
    if (ctx.mode !== "tui") return;

    ctx.ui.setFooter((tui, theme) => {
      let previous: ReturnType<typeof cpuSnapshot>;
      let cpu: number | undefined;
      let ram: number | undefined;
      const sample = () => {
        const current = cpuSnapshot();
        const elapsed = current && previous ? current.total - previous.total : 0;
        cpu = current && previous && elapsed > 0
          ? Math.max(0, Math.min(100, (1 - (current.idle - previous.idle) / elapsed) * 100))
          : undefined;
        previous = current;
        try {
          const total = totalmem();
          ram = total > 0 ? Math.max(0, Math.min(100, (1 - freemem() / total) * 100)) : undefined;
        } catch {
          ram = undefined;
        }
      };
      sample();
      const timer = setInterval(() => {
        sample();
        tui.requestRender();
      }, 2_000);
      timer.unref();
      dispose = () => clearInterval(timer);

      const meter = (value: number | null | undefined) => theme.fg(
        value != null && value >= 90 ? "error" : value != null && value >= 70 ? "warning" : "muted",
        percent(value),
      );

      return {
        dispose,
        // 每次 render 都读取主题及当前会话，不缓存带颜色的文本。
        invalidate() {},
        render(width: number): string[] {
          if (width <= 0) return [""];
          const model = ctx.model;
          const mark = theme.fg("accent", providerMark(model?.provider ?? ""));
          const name = clean(model?.name || model?.id || "no model");
          const modelText = theme.fg("accent", name);
          const thinking = theme.fg("muted", `⚡️ ${pi.getThinkingLevel()}`);
          const path = theme.fg("dim", `📁 ${shortPath(ctx.cwd)}`);
          const leaf = theme.fg("dim", `📁 ${shortPath(ctx.cwd, true)}`);
          // Pi 在压缩后可能尚无上下文统计，未知用 ?，容量回退到模型声明。
          const usage = ctx.getContextUsage();
          const context = theme.fg("muted", `📊 ${tokens(usage?.tokens)} / ${tokens(usage?.contextWindow ?? model?.contextWindow)}`)
            + theme.fg("dim", " (") + meter(usage?.percent) + theme.fg("dim", ")");
          const resources = theme.fg("dim", "· CPU ") + meter(cpu)
            + theme.fg("dim", " / RAM ") + meter(ram);
          const layouts = [
            [mark, modelText, thinking, path, context, resources],
            [mark, modelText, thinking, leaf, context, resources],
            [mark, modelText, thinking, leaf, context],
            [mark, modelText, thinking, context],
            [mark, modelText, context],
          ];
          for (const parts of layouts) {
            const line = parts.join(" ");
            if (visibleWidth(line) <= width) return [line];
          }
          // 极窄窗口缩短模型名，保留上下文；不足以容纳时只显示上下文。
          const modelWidth = width - visibleWidth(context) - 1;
          if (modelWidth < 4) return [truncateToWidth(context, width)];
          return [truncateToWidth(modelText, modelWidth) + " " + context];
        },
      };
    });
  });

  pi.on("session_shutdown", () => dispose());
}
