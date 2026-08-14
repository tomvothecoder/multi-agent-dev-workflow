# NERSC Filesystem Rules

For NERSC environments, run:

```bash
make install-nersc-rules
```

This installs bounded-filesystem-discovery rules for OpenCode. The canonical copy is [`~/.config/ai-instructions/nersc-filesystem.md`](../profiles/nersc/nersc-filesystem.md). The profile preserves existing OpenCode instructions and can be removed with:

```bash
make uninstall-nersc-rules
```
