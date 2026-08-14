## Filesystem discovery

- Never recursively traverse `/`, `/global`, `/global/cfs`, `/global/homes`,
  `/pscratch`, `/opt`, `/usr`, or another shared top-level directory. This
  prohibition applies on compute nodes as well as login nodes.
- This prohibition includes `find`, `bfs`, `fd`, `tree`, recursive `du`,
  `rg --files`, recursive `grep`, recursive `ls`, globstar expansion, and
  recursive traversal written in Python or another language.
- Before searching, identify a bounded root inside the current workspace or a
  known project or data directory. Constrain depth and filename patterns where
  possible. If no bounded root is known, stop and ask the user.
- Locate software with `command -v`, `type -a`, `module spider`, package
  metadata, or known environment prefixes. Do not search mounted filesystems
  for executables.
- Do not disable or bypass an installed filesystem-traversal hook, and do not
  ask the user to approve an equivalent broad scan through another command.
- A compute allocation is not permission for an unbounded traversal of a
  shared filesystem. Narrow the search first; route only bounded,
  computationally substantial searches through `$perlmutter-compute`.
