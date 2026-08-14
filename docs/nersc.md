# NERSC Filesystem Rules

For NERSC environments, run:

```bash
make install-nersc-rules
```

This installs bounded-filesystem-discovery rules for Codex, Claude, OpenCode, and Copilot. The canonical copy is [`~/.config/ai-instructions/nersc-filesystem.md`](../profiles/nersc/nersc-filesystem.md). The profile preserves existing instruction files and can be removed with:

```bash
make uninstall-nersc-rules
```

When the workflow package manages Codex's `~/.codex/AGENTS.md` symlink, the profile installs a dedicated `nersc-filesystem` Codex skill instead of changing that managed file.
