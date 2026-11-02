# Repository Purpose

- This repository archives personal configuration files that are safe to publish.
- The repository root mirrors `$HOME/.config`; preserve each file's path below that directory. Do not flatten paths or regroup files by application or topic.
- If a source path's anchor (for example, `$HOME` versus `/`) is not already established in the repository, ask before choosing a destination.

# Content Boundaries

- Add configuration only; exclude generated files, caches, runtime state, logs, backups, and machine-local data.
- Exceptions: root `setup.sh` registers only the global `/onboard` README entrypoint and removes its unchanged legacy navigation; `uninstall.sh` previews or explicitly archives verified legacy installation artifacts; `install.sh` is a side-effect-free retirement notice that exits nonzero. Keep these scripts self-contained. Generated commands, migration archives, state and scheduler artifacts must stay outside the repository.
- Never commit credentials or private data. Replace tokens, passwords, private keys, cookies, account IDs, internal hosts, and similar values with clear placeholders when a usable public example is needed.
- Keep public defaults separate from local overrides; local or secret-bearing variants must remain outside the repository.

# Working Convention

- For this repository, work directly in the current working directory by default; the user has permanently authorized skipping linked Worktrees. Preserve unrelated changes. Commit, merge, and push still require separate authorization.
- Preserve dotfile names and application-native formats; avoid wrapper scripts or transformed copies unless the repository already uses them for that configuration.
- Keep changes scoped to the requested configuration and its mirrored path. Do not reformat unrelated files.
- `opencode/README.md` is the sole OpenCode introduction and update guide. Keep the root README as concise navigation. Changes to OpenCode usage, agent workflows, skills or migration behavior must update that guide and its update notes in the same change.
- OpenCode sources are project-adaptation references, not a global installation bundle. `/onboard` is a thin README entrypoint without a fixed agent or model, not a copy of the workflow. Do not override built-in `/init` or restore automatic global agent/skill synchronization. Generated project files must be self-contained and preserve existing project conventions and private configuration. Initialization must prepare the new agent before switching; never disable the agent executing the current onboarding request.
- There is currently no repository-wide build, lint, or test command. Verify changes with the relevant application's native config check when available, then inspect the final diff for path mistakes and sensitive data.
