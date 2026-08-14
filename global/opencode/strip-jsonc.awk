# Remove JSONC line and block comments while preserving comment-like text in strings.
function emit_line(line,    i, c, next_c, quoted, escaped, output) {
  quoted = 0
  escaped = 0
  output = ""
  for (i = 1; i <= length(line); i++) {
    c = substr(line, i, 1)
    next_c = substr(line, i + 1, 1)
    if (in_block_comment) {
      if (c == "*" && next_c == "/") {
        in_block_comment = 0
        i++
      }
      continue
    }
    if (quoted) {
      output = output c
      if (escaped) {
        escaped = 0
      } else if (c == "\\") {
        escaped = 1
      } else if (c == "\"") {
        quoted = 0
      }
      continue
    }
    if (c == "\"") {
      quoted = 1
      output = output c
    } else if (c == "/" && next_c == "/") {
      break
    } else if (c == "/" && next_c == "*") {
      in_block_comment = 1
      i++
    } else {
      output = output c
    }
  }
  print output
}

{ emit_line($0) }
