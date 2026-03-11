# CodeMap for Copilot

- Use CodeMap before broad text search when the user asks about project structure, module boundaries, symbol definitions, call relationships, or refactor impact.
- If `.codemap/graph.json` does not exist, run a full scan first.
- If the graph exists but the code changed, run an incremental update before answering structural questions.
- On Windows, prefer `C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe`.
- On macOS or Linux, prefer `codegraph` from `PATH`, otherwise use the platform binary under `~/.codemap/bin/`.
- Common commands:
  - `codegraph scan .`
  - `codegraph status .`
  - `codegraph query SYMBOL --dir .`
  - `codegraph slice MODULE --dir .`
  - `codegraph impact TARGET --dir .`
  - `codegraph update .`
- When reporting CodeMap output, summarize the relevant modules, files, and references instead of dumping raw JSON unless the user asks for the raw output.
