---
name: agent-browser
description: Use agent-browser for browser automation, navigating websites, filling forms, clicking buttons, taking screenshots, extracting page data, and testing web applications. Also use for exploratory QA and Electron desktop app automation.
---

# agent-browser

Use the installed `agent-browser` CLI through the shell tool. If the command is
unavailable, report that prerequisite instead of installing it implicitly. This
is a CLI skill, not an MCP server; no npm or npx invocation is needed.

Before browser automation, load the version-matched workflow from the CLI:

```bash
agent-browser skills get core
```

For full command reference and templates:

```bash
agent-browser skills get core --full
```

Basic workflow:

1. `agent-browser open <url>`
2. `agent-browser snapshot -i`
3. Interact using the returned refs, such as `agent-browser click @e1`.
4. Take a fresh snapshot after navigation or page changes.
5. `agent-browser close` when finished.

Use `agent-browser skills list` to discover specialized workflows and
`agent-browser skills get <name>` to load them when needed.
Use a distinct `--session <name>` for independent browser tasks.
Follow the user's existing permission and confirmation rules for browser actions.
