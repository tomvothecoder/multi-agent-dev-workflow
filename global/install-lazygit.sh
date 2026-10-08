#!/usr/bin/env bash
set -euo pipefail

fail() { printf '%s\n' "$*" >&2; exit 1; }
report() {
  printf 'Lazygit executable: %s\n' "$1"
  "$1" --version
}
matches_version() {
  [[ "$1" =~ (^|[[:space:],])version=([^,[:space:]]+) ]] && [ "${BASH_REMATCH[2]}" = "$2" ]
}
path_hint() {
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) printf 'Add ~/.local/bin to PATH before starting Lazygit, for example:\n  export PATH="$HOME/.local/bin:$PATH"\nNo shell configuration was modified.\n' ;;
  esac
}

platform="$(uname -s)"
version="${LAZYGIT_VERSION:-}"
version="${version#v}"
if [ -n "${LAZYGIT_VERSION:-}" ] && ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  fail 'LAZYGIT_VERSION must be a release version such as 0.66.0 or v0.66.0.'
fi
existing="$(command -v lazygit || true)"
case "$platform" in
  Darwin)
    [ -z "$version" ] || fail 'LAZYGIT_VERSION pinning is supported only on Linux; macOS uses Homebrew.'
    if [ -n "$existing" ]; then
      printf 'Preserved existing installation.\n'
      report "$existing"
      exit 0
    fi
    command -v brew >/dev/null || fail 'Homebrew is required. Install it using https://brew.sh/, then run make install-lazygit again.'
    brew install lazygit
    executable="$(command -v lazygit || true)"
    [ -n "$executable" ] || executable="$(brew --prefix lazygit)/bin/lazygit"
    report "$executable"
    ;;
  Linux)
    case "$(uname -m)" in
      x86_64|amd64) arch=x86_64 ;;
      aarch64|arm64) arch=arm64 ;;
      armv6l|armv7l) arch=armv6 ;;
      i386|i486|i586|i686) arch=32-bit ;;
      *) fail "Unsupported Linux architecture: $(uname -m)" ;;
    esac
    destination="$HOME/.local/bin/lazygit"
    [ ! -L "$destination" ] || fail "Refusing to replace symlink: $destination"
    if [ -e "$destination" ] && { [ ! -f "$destination" ] || [ ! -x "$destination" ]; }; then
      fail "Refusing to replace a non-executable or non-file: $destination"
    fi
    if [ -z "$existing" ] && [ -x "$destination" ]; then existing="$destination"; fi
    if [ -n "$existing" ]; then
      installed="$("$existing" --version)"
      if [ -z "$version" ] || matches_version "$installed" "$version"; then
        printf 'Preserved existing installation.\n'
        report "$existing"
        path_hint
        exit 0
      fi
      [ "$existing" = "$destination" ] || fail "Existing Lazygit at $existing does not match $version. Manage it with its original installer or remove it from PATH first; it was not changed."
    fi
    for tool in curl tar sha256sum; do
      command -v "$tool" >/dev/null || fail "Required tool not found: $tool"
    done
    if [ -z "$version" ]; then
      release_url="$(curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --output /dev/null --write-out '%{url_effective}' https://github.com/jesseduffield/lazygit/releases/latest)"
      version="${release_url##*/v}"
      [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'Could not determine the latest Lazygit release.'
    fi
    scratch="$(mktemp -d)"
    staged=''
    trap 'rm -rf "$scratch"; if [ -n "$staged" ]; then rm -f "$staged"; fi' EXIT
    archive=''
    base="https://github.com/jesseduffield/lazygit/releases/download/v$version"
    curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' "$base/checksums.txt" --output "$scratch/checksums.txt"
    checksum=''
    while read -r hash name extra; do
      # Older official releases used Linux rather than linux in asset names.
      if [ "$name" = "lazygit_${version}_linux_${arch}.tar.gz" ] || [ "$name" = "lazygit_${version}_Linux_${arch}.tar.gz" ]; then
        [ -z "$checksum" ] || fail "Duplicate Linux release checksum for $arch"
        [[ "$hash" =~ ^[[:xdigit:]]{64}$ ]] && [ -z "$extra" ] || fail "Invalid checksum for $name"
        archive="$name"
        checksum="$hash"
      fi
    done < "$scratch/checksums.txt"
    [ -n "$checksum" ] || fail "Published Linux checksum not found for version $version, architecture $arch"
    curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' "$base/$archive" --output "$scratch/$archive"
    actual="$(sha256sum "$scratch/$archive")"
    [ "${actual%% *}" = "$checksum" ] || fail "Checksum verification failed for $archive"
    # Extract only the executable, not other archive paths.
    tar -xzf "$scratch/$archive" -C "$scratch" lazygit
    [ -f "$scratch/lazygit" ] && [ ! -L "$scratch/lazygit" ] || fail 'Release archive did not contain a regular lazygit binary.'
    chmod 755 "$scratch/lazygit"
    installed="$("$scratch/lazygit" --version)"
    matches_version "$installed" "$version" || fail 'Downloaded executable did not report the requested version.'
    mkdir -p "$HOME/.local/bin"
    staged="$(mktemp "$HOME/.local/bin/.lazygit.XXXXXX")"
    cp "$scratch/lazygit" "$staged"
    chmod 755 "$staged"
    mv -f "$staged" "$destination"
    staged=''
    report "$destination"
    path_hint
    ;;
  *) fail "Unsupported platform: $platform (expected macOS or Linux)." ;;
esac
