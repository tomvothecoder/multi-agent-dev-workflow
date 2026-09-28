#!/usr/bin/env python3
"""Synchronize selected user-owned OpenCode configuration sections from the template."""

import argparse
import os
import stat
import sys
import tempfile
from pathlib import Path


def skip_whitespace_and_comments(text, position):
    while position < len(text):
        if text[position].isspace():
            position += 1
        elif text.startswith("//", position):
            newline = text.find("\n", position)
            position = len(text) if newline == -1 else newline + 1
        elif text.startswith("/*", position):
            end = text.find("*/", position + 2)
            if end == -1:
                raise ValueError("unterminated block comment")
            position = end + 2
        else:
            break
    return position


def string_end(text, position):
    if text[position] != '"':
        raise ValueError("expected string")
    position += 1
    while position < len(text):
        if text[position] == "\\":
            position += 2
        elif text[position] == '"':
            return position + 1
        else:
            position += 1
    raise ValueError("unterminated string")


def value_end(text, position):
    position = skip_whitespace_and_comments(text, position)
    if position >= len(text):
        raise ValueError("missing value")
    if text[position] == '"':
        return string_end(text, position)
    if text[position] not in "[{":
        end = position
        while end < len(text) and text[end] not in ",}]\r\n\t ":
            end += 1
        return end

    opening = text[position]
    closing = "}" if opening == "{" else "]"
    depth = 0
    while position < len(text):
        character = text[position]
        if character == '"':
            position = string_end(text, position)
        elif text.startswith("//", position):
            position = skip_whitespace_and_comments(text, position)
        elif text.startswith("/*", position):
            position = skip_whitespace_and_comments(text, position)
        elif character == opening:
            depth += 1
            position += 1
        elif character == closing:
            depth -= 1
            position += 1
            if depth == 0:
                return position
        else:
            position += 1
    raise ValueError("unterminated value")


def object_property(text, object_position, name):
    position = skip_whitespace_and_comments(text, object_position)
    if position >= len(text) or text[position] != "{":
        raise ValueError("expected object")
    position += 1
    while True:
        position = skip_whitespace_and_comments(text, position)
        if position >= len(text):
            raise ValueError("unterminated object")
        if text[position] == "}":
            break
        key_start = position
        key_end = string_end(text, position)
        key = text[key_start + 1 : key_end - 1]
        position = skip_whitespace_and_comments(text, key_end)
        if position >= len(text) or text[position] != ":":
            raise ValueError("expected colon after object key")
        start = skip_whitespace_and_comments(text, position + 1)
        end = value_end(text, start)
        if key == name:
            return start, end
        position = skip_whitespace_and_comments(text, end)
        if position >= len(text) or text[position] == "}":
            break
        if text[position] != ",":
            raise ValueError("expected comma between object properties")
        position += 1
    raise KeyError(name)


def section_span(text, section):
    if section == "livai-models":
        provider_start, _ = object_property(text, 0, "provider")
        livai_start, _ = object_property(text, provider_start, "livai")
        return object_property(text, livai_start, "models")
    if section == "agents":
        return object_property(text, 0, "agent")
    return object_property(text, 0, "permission")


def synchronize(template_text, destination_text, sections):
    replacements = []
    for section in sections:
        template_start, template_end = section_span(template_text, section)
        destination_start, destination_end = section_span(destination_text, section)
        replacements.append(
            (destination_start, destination_end, template_text[template_start:template_end])
        )
    previous_end = -1
    for start, end, _ in sorted(replacements):
        if start < previous_end:
            raise ValueError("requested sections overlap")
        previous_end = end
    updated = destination_text
    for start, end, replacement in sorted(replacements, reverse=True):
        updated = updated[:start] + replacement + updated[end:]
    return updated


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "sections",
        choices=("livai-models", "agents", "permissions"),
        nargs="+",
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parent
    template = root / "opencode" / "opencode.jsonc"
    config_dir = Path(os.environ.get("OPENCODE_CONFIG_DIR", Path.home() / ".config/opencode"))
    destination = config_dir / "opencode.jsonc"
    if not config_dir.is_dir():
        raise SystemExit("OpenCode configuration directory does not exist: {}".format(config_dir))
    if destination.is_symlink():
        raise SystemExit("Refusing to replace symlinked OpenCode configuration: {}".format(destination))
    if not destination.is_file():
        raise SystemExit("OpenCode configuration does not exist: {}".format(destination))

    try:
        destination_text = destination.read_text()
        updated = synchronize(template.read_text(), destination_text, args.sections)
    except (KeyError, ValueError) as error:
        raise SystemExit("Could not synchronize OpenCode configuration: {}".format(error))

    if updated == destination_text:
        print("Selected OpenCode configuration sections already match the template: {}".format(destination))
        return

    mode = stat.S_IMODE(destination.stat().st_mode)
    temporary_path = None
    try:
        with tempfile.NamedTemporaryFile("w", dir=str(config_dir), delete=False) as temporary:
            temporary.write(updated)
            temporary_path = Path(temporary.name)
        temporary_path.chmod(mode)
        temporary_path.replace(destination)
    except OSError:
        if temporary_path is not None and temporary_path.exists():
            temporary_path.unlink()
        raise
    print("Updated {} from the OpenCode template: {}".format(", ".join(args.sections), destination))


if __name__ == "__main__":
    main()
