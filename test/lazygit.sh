#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
mkdir -p "$TEST_DIR/bin" "$TEST_DIR/home" "$TEST_DIR/tmp" "$TEST_DIR/release"
export HOME="$TEST_DIR/home" TMPDIR="$TEST_DIR/tmp"
# Do not see host installations of Lazygit or Homebrew.
for tool in bash make dirname cat cp tar sha256sum chmod mktemp rm mv mkdir ls rg cmp ln ruby; do
  ln -s "$(command -v "$tool")" "$TEST_DIR/bin/$tool"
done
export PATH="$TEST_DIR/bin"
export TEST_DIR
unset LAZYGIT_VERSION LG_CONFIG_FILE CONFIG_DIR XDG_CONFIG_HOME

# All network and platform commands are mocked; real tar/checksum/YAML code runs.
cat > "$TEST_DIR/bin/uname" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  -s) printf '%s\n' "${TEST_OS:-Linux}" ;;
  -m) printf '%s\n' "${TEST_ARCH:-x86_64}" ;;
  *) exit 1 ;;
esac
EOF
cat > "$TEST_DIR/release/lazygit" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  --version) printf 'version=0.66.0, build source=binaryBuild\n' ;;
  --help) if [ "${TEST_OLD_CLI:-0}" = 0 ]; then printf '%s\n' '--print-config-dir'; fi ;;
  --print-config-dir) [ "${TEST_CONFIG_FAIL:-0}" = 0 ] || exit 1; printf '%s\n' "$TEST_DIR/active config" ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$TEST_DIR/bin/uname" "$TEST_DIR/release/lazygit"
tar -czf "$TEST_DIR/release.tar.gz" -C "$TEST_DIR/release" lazygit
cat > "$TEST_DIR/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$TEST_DIR/downloads"
[ "${TEST_DOWNLOAD_FAIL:-0}" = 0 ] || exit 22
output=''
url=''
while [ "$#" -gt 0 ]; do
  case "$1" in
    --output) output="$2"; shift ;;
    https://*) url="$1" ;;
  esac
  shift
done
case "$url" in
  */latest) printf 'https://github.com/jesseduffield/lazygit/releases/tag/v0.66.0' ;;
  */checksums.txt)
    archive="lazygit_0.66.0_${TEST_ASSET_OS:-linux}_${TEST_ASSET_ARCH:-x86_64}.tar.gz"
    hash="$(sha256sum "$TEST_DIR/release.tar.gz")"
    if [ "${TEST_BAD_CHECKSUM:-0}" = 1 ]; then hash="$(printf '%064d' 0)"; fi
    if [ "${TEST_MISSING_CHECKSUM:-0}" = 1 ]; then archive=unrelated.tar.gz; fi
    printf '%s  %s\n' "${hash%% *}" "$archive" > "$output"
    if [ "${TEST_DUPLICATE_CHECKSUM:-0}" = 1 ]; then printf '%s  %s\n' "${hash%% *}" "$archive" >> "$output"; fi
    ;;
  */lazygit_0.66.0_linux_*.tar.gz|*/lazygit_0.66.0_Linux_*.tar.gz) cp "$TEST_DIR/release.tar.gz" "$output" ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$TEST_DIR/bin/curl"

install_lazygit() { make -s -C "$ROOT" install-lazygit > "$TEST_DIR/output" 2>&1; }
setup_lazygit() { make -s -C "$ROOT" setup-lazygit > "$TEST_DIR/output" 2>&1; }
expect_failure() {
  if "$@"; then printf 'Expected failure: %s\n' "$*" >&2; exit 1; fi
}
assert_clean() { test -z "$(ls -A "$TEST_DIR/tmp")"; }

# Supported architecture aliases select the published asset name.
for pair in x86_64:x86_64 amd64:x86_64 aarch64:arm64 arm64:arm64 armv6l:armv6 armv7l:armv6 i386:32-bit i686:32-bit; do
  export TEST_ARCH="${pair%%:*}" TEST_ASSET_ARCH="${pair#*:}"
  rm -f "$HOME/.local/bin/lazygit" "$TEST_DIR/downloads"
  LAZYGIT_VERSION=v0.66.0 install_lazygit
  rg -Fq "lazygit_0.66.0_linux_${TEST_ASSET_ARCH}.tar.gz" "$TEST_DIR/downloads"
  rg -Fq "Lazygit executable: $HOME/.local/bin/lazygit" "$TEST_DIR/output"
  rg -Fq 'Add ~/.local/bin to PATH' "$TEST_DIR/output"
  assert_clean
done
export TEST_ARCH=x86_64 TEST_ASSET_ARCH=x86_64
# Existing local binary (even outside PATH) is preserved, with no download.
cp "$HOME/.local/bin/lazygit" "$TEST_DIR/before"
rm "$TEST_DIR/downloads"
install_lazygit
test ! -e "$TEST_DIR/downloads"
cmp "$TEST_DIR/before" "$HOME/.local/bin/lazygit"
LAZYGIT_VERSION=0.66.0 install_lazygit
test ! -e "$TEST_DIR/downloads"
PATH="$HOME/.local/bin:$PATH" install_lazygit
if rg -Fq 'Add ~/.local/bin to PATH' "$TEST_DIR/output"; then exit 1; fi
# Official releases historically used a capitalized Linux asset name.
rm "$HOME/.local/bin/lazygit"
TEST_ASSET_OS=Linux LAZYGIT_VERSION=0.66.0 install_lazygit
rg -Fq 'lazygit_0.66.0_Linux_x86_64.tar.gz' "$TEST_DIR/downloads"
# Latest discovery, unsupported platforms/architectures, invalid versions.
rm "$HOME/.local/bin/lazygit"
install_lazygit
rg -Fq '/releases/latest' "$TEST_DIR/downloads"
TEST_ARCH=riscv64 expect_failure install_lazygit
TEST_OS=FreeBSD expect_failure install_lazygit
LAZYGIT_VERSION='../oops' expect_failure install_lazygit
LAZYGIT_VERSION=v expect_failure install_lazygit

# Failures preserve an older executable and remove download/staging files.
cat > "$HOME/.local/bin/lazygit" <<'EOF'
#!/usr/bin/env bash
printf 'version=0.65.0, old\n'
EOF
cp "$HOME/.local/bin/lazygit" "$TEST_DIR/before"
for failure in TEST_BAD_CHECKSUM TEST_MISSING_CHECKSUM TEST_DUPLICATE_CHECKSUM TEST_DOWNLOAD_FAIL; do
  export "$failure=1"
  LAZYGIT_VERSION=0.66.0 expect_failure install_lazygit
  cmp "$TEST_DIR/before" "$HOME/.local/bin/lazygit"
  assert_clean
  unset "$failure"
done
# Even checksum-valid archives must extract and report the requested version.
cp "$TEST_DIR/release.tar.gz" "$TEST_DIR/release-good.tar.gz"
printf 'not a tar archive\n' > "$TEST_DIR/release.tar.gz"
LAZYGIT_VERSION=0.66.0 expect_failure install_lazygit
cmp "$TEST_DIR/before" "$HOME/.local/bin/lazygit"
assert_clean
tar -czf "$TEST_DIR/release.tar.gz" -C "$HOME/.local/bin" lazygit
LAZYGIT_VERSION=0.66.0 expect_failure install_lazygit
rg -Fq 'Downloaded executable did not report the requested version.' "$TEST_DIR/output"
cmp "$TEST_DIR/before" "$HOME/.local/bin/lazygit"
assert_clean
mv "$TEST_DIR/release-good.tar.gz" "$TEST_DIR/release.tar.gz"
LAZYGIT_VERSION=0.66.0 install_lazygit
# Missing prerequisites fail before downloads or changes to the destination.
mv "$TEST_DIR/bin/sha256sum" "$TEST_DIR/sha256sum"
cp "$TEST_DIR/before" "$HOME/.local/bin/lazygit"
LAZYGIT_VERSION=0.66.0 expect_failure install_lazygit
rg -Fq 'Required tool not found: sha256sum' "$TEST_DIR/output"
cmp "$TEST_DIR/before" "$HOME/.local/bin/lazygit"
mv "$TEST_DIR/sha256sum" "$TEST_DIR/bin/sha256sum"
LAZYGIT_VERSION=0.66.0 install_lazygit
# Symlinks and externally managed mismatched binaries are not overwritten.
mv "$HOME/.local/bin/lazygit" "$TEST_DIR/saved"
ln -s "$TEST_DIR/saved" "$HOME/.local/bin/lazygit"
LAZYGIT_VERSION=0.66.0 expect_failure install_lazygit
test -L "$HOME/.local/bin/lazygit"
rm "$HOME/.local/bin/lazygit"
cp "$TEST_DIR/before" "$TEST_DIR/bin/lazygit"
LAZYGIT_VERSION=0.66.0 expect_failure install_lazygit
cmp "$TEST_DIR/before" "$TEST_DIR/bin/lazygit"
rm "$TEST_DIR/bin/lazygit"

# Homebrew install, preservation, and missing-Homebrew instructions.
cat > "$TEST_DIR/bin/brew" <<'EOF'
#!/usr/bin/env bash
set -eu
[ "$*" = 'install lazygit' ]
printf '%s\n' "$*" >> "$TEST_DIR/brew-log"
[ "${TEST_BREW_FAIL:-0}" = 0 ] || exit 1
cp "$TEST_DIR/release/lazygit" "$TEST_DIR/bin/lazygit"
EOF
chmod +x "$TEST_DIR/bin/brew"
TEST_OS=Darwin TEST_BREW_FAIL=1 expect_failure install_lazygit
TEST_OS=Darwin install_lazygit
rg -Fxq 'install lazygit' "$TEST_DIR/brew-log"
cp "$TEST_DIR/brew-log" "$TEST_DIR/before-log"
TEST_OS=Darwin install_lazygit
cmp "$TEST_DIR/before-log" "$TEST_DIR/brew-log"
rm "$TEST_DIR/bin/lazygit"
# A non-executable placeholder hides any host Homebrew from command -v.
printf '#!/bin/sh\nexit 1\n' > "$TEST_DIR/bin/brew"
chmod -x "$TEST_DIR/bin/brew"
# Use a minimal PATH so the real host brew/lazygit cannot leak into this case.
mkdir "$TEST_DIR/minimal"
for tool in bash uname make; do ln -s "$(command -v "$tool")" "$TEST_DIR/minimal/$tool"; done
TEST_OS=Darwin PATH="$TEST_DIR/minimal" expect_failure install_lazygit
rg -Fq 'https://brew.sh/' "$TEST_DIR/output"

# CLI directory wins over XDG; setup can use the just-installed local binary.
cp "$TEST_DIR/release/lazygit" "$HOME/.local/bin/lazygit"
export XDG_CONFIG_HOME="$TEST_DIR/xdg"
setup_lazygit
config="$TEST_DIR/active config/config.yml"
test -f "$config"
test ! -e "$XDG_CONFIG_HOME/lazygit/config.yml"
cp "$config" "$TEST_DIR/config-before"
setup_lazygit
cmp "$TEST_DIR/config-before" "$config"
TEST_CONFIG_FAIL=1 expect_failure setup_lazygit
LG_CONFIG_FILE=/some/config.yml expect_failure setup_lazygit
mv "$TEST_DIR/bin/ruby" "$TEST_DIR/ruby"
expect_failure setup_lazygit
rg -Fq 'Ruby with the standard-library psych YAML parser is required' "$TEST_DIR/output"
mv "$TEST_DIR/ruby" "$TEST_DIR/bin/ruby"

# Fallback locations respect XDG on either platform, CONFIG_DIR, and defaults.
TEST_OLD_CLI=1 TEST_OS=Darwin setup_lazygit
test -f "$XDG_CONFIG_HOME/lazygit/config.yml"
TEST_OLD_CLI=1 CONFIG_DIR="$TEST_DIR/custom" setup_lazygit
test -f "$TEST_DIR/custom/config.yml"
unset XDG_CONFIG_HOME
TEST_OLD_CLI=1 TEST_OS=Darwin setup_lazygit
test -f "$HOME/Library/Application Support/lazygit/config.yml"
TEST_OLD_CLI=1 TEST_OS=Linux setup_lazygit
test -f "$HOME/.config/lazygit/config.yml"

# Source-span editing preserves comments, other settings, and exact repeat output.
cat > "$config" <<'EOF'
# prologue
gui:
  nerdFontsVersion: "3" # keep this
worktree: # keep section comment
  defaultPath: /old/path # keep inline comment
  other: true
git:
  autoFetch: false
# epilogue
EOF
setup_lazygit
rg -Fq "  defaultPath: '~/worktrees' # keep inline comment" "$config"
rg -Fq 'worktree: # keep section comment' "$config"
rg -Fq '  nerdFontsVersion: "3" # keep this' "$config"
rg -Fq '# epilogue' "$config"
cp "$config" "$TEST_DIR/config-before"
setup_lazygit
cmp "$TEST_DIR/config-before" "$config"

for yaml in \
  'worktree: {other: true} # flow' \
  'worktree: {other: true,} # trailing comma' \
  $'worktree: {other: true, # keep comment\n}' \
  '{gui: {},}' \
  '{gui: {mouseEvents: false}, worktree: {defaultPath: /old}} # root flow' \
  $'worktree:\n  defaultPath:' \
  $'worktree:\n  defaultPath: # keep empty value comment\n  other: true' \
  'worktree: {defaultPath: ~}' \
  'worktree: null # keep null section comment' \
  $'worktree: # keep empty section comment\ngui: {}' \
  '{}' \
  $'worktree:\n    other: true\ngui: {}' \
  $'# comments only\n' \
  $'---\n# empty document\n...\n' \
  $'gui: {}\r\nworktree: {defaultPath: old}\r\n'; do
  printf '%s\n' "$yaml" > "$config"
  setup_lazygit
  ruby -r psych -e 'abort unless Psych.safe_load(File.read(ARGV[0]))["worktree"]["defaultPath"] == "~/worktrees"' "$config"
  cp "$config" "$TEST_DIR/config-before"
  setup_lazygit
  cmp "$TEST_DIR/config-before" "$config"
done

# Invalid or ambiguous configurations fail before writing.
for yaml in \
  'gui: [unterminated' \
  $'worktree: {}\nworktree: {}' \
  $'worktree: {defaultPath: old, defaultPath: duplicate}' \
  'worktree: scalar' \
  '- not-a-mapping' \
  $'---\n{}\n---\n{}' \
  'gui: *missing' \
  $'worktree: &shared {defaultPath: old}\ngui: *shared' \
  $'worktree:\n  defaultPath: | # keep\n    /old/path'; do
  printf '%s\n' "$yaml" > "$config"
  cp "$config" "$TEST_DIR/config-before"
  expect_failure setup_lazygit
  cmp "$TEST_DIR/config-before" "$config"
  rg -Fq 'Could not configure Lazygit:' "$TEST_DIR/output"
done
rm "$config"
ln -s "$TEST_DIR/config-before" "$config"
expect_failure setup_lazygit
test -L "$config"
# Missing installation gives actionable setup instructions.
rm "$HOME/.local/bin/lazygit"
expect_failure setup_lazygit
rg -Fq 'Run make install-lazygit first.' "$TEST_DIR/output"
printf 'Lazygit test passed.\n'
