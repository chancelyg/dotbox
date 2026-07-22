# Repository Purpose

- This repository archives personal configuration files that are safe to publish.
- The repository root mirrors `$HOME/.config`; preserve each file's path below that directory. Do not flatten paths or regroup files by application or topic.
- If a source path's anchor (for example, `$HOME` versus `/`) is not already established in the repository, ask before choosing a destination.

# Content Boundaries

- Add configuration only; exclude generated files, caches, runtime state, logs, backups, and machine-local data.
- Never commit credentials or private data. Replace tokens, passwords, private keys, cookies, account IDs, internal hosts, and similar values with clear placeholders when a usable public example is needed.
- Keep public defaults separate from local overrides; local or secret-bearing variants must remain outside the repository.

# Working Convention

- Preserve dotfile names and application-native formats; avoid wrapper scripts or transformed copies unless the repository already uses them for that configuration.
- Keep changes scoped to the requested configuration and its mirrored path. Do not reformat unrelated files.
- There is currently no repository-wide build, lint, or test command. Verify changes with the relevant application's native config check when available, then inspect the final diff for path mistakes and sensitive data.
