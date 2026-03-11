---
name: codemap
description: >
  CodeMap code graph routing for GitHub Copilot and VS Code Agent Plugins.
  Use when the user asks about project structure, architecture, modules,
  symbol definitions, references, refactor impact, or code graph freshness.
---

# CodeMap for Copilot

CodeMap builds a structural graph under `.codemap/` so you can answer repository
questions without rereading the whole codebase.

## Routing

### 1. Check whether the graph exists

PowerShell:

```powershell
if (Test-Path ".codemap/graph.json") { "CODEMAP_EXISTS" } else { "NO_CODEMAP" }
```

Bash:

```bash
test -f .codemap/graph.json && echo "CODEMAP_EXISTS" || echo "NO_CODEMAP"
```

If it does not exist, recommend `/codemap:scan`.

### 2. Resolve the executable

Prefer:

- Windows: `C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe`
- Otherwise: `codegraph` from `PATH`

### 3. Route by user intent

- Repository overview or session start: `/codemap:load`
- Specific module: `/codemap:load <module>`
- Symbol definition or references: `/codemap:query <symbol>`
- Variables/constants: `/codemap:query <symbol> --type variable`
- Refactor impact: `/codemap:impact <target>`
- Code changed: `/codemap:update`
- Graph missing: `/codemap:scan`
- Copilot instructions setup: `/codemap:prompts`

### 4. Keep answers compact

Summarize modules, files, dependencies, and affected call sites. Only read source
files when the user asks for the implementation details.
