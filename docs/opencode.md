# OpenCode Configuration

The core OpenCode configuration is user-owned. This repository provides the separate core host template at `global/opencode/opencode.jsonc`.

`make install` never writes, links, or overwrites user-owned `opencode.json` or `opencode.jsonc`.

To explicitly initialize a user-owned `opencode.jsonc` from this repository's template, run:

```bash
make install-opencode-config
```

The command copies the template to `${OPENCODE_CONFIG_DIR:-~/.config/opencode}/opencode.jsonc` only when that destination is absent. It refuses to replace an existing file or symlink, so subsequent edits remain user-owned.

For the Slim plugin configuration, installation sequence, and hybrid customizations, see [Slim setup and configuration](../README.md#slim-setup-and-configuration).
