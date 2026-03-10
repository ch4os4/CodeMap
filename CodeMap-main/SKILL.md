---
name: codemap
description: >
  CodeMap for Codex/OpenAI agents. Use when you need fast codebase understanding,
  project overview, module slicing, symbol lookup, dependency tracing, or refactor
  impact analysis without re-reading the whole repository. Trigger before major code
  changes, when the user asks where a function/class/module is defined, who depends on it,
  or when a .codemap/ graph exists or should be created.
---

# CodeMap

CodeMap persists an AST-based code graph in `.codemap/` and lets the agent load small structural slices instead of full source.

## Launcher

- Windows: use `.\bin\codegraph.cmd`
- macOS/Linux: use `bash ./bin/codegraph`

The launcher will reuse a local build when present and otherwise download the matching release binary.

## Workflow

### 1. Ensure the graph exists

Check whether `<project>/.codemap/graph.json` exists.

- Missing: run a full scan.

```powershell
.\bin\codegraph.cmd scan <project>
```

```bash
bash ./bin/codegraph scan <project>
```

### 2. Check freshness before relying on old graph data

```powershell
.\bin\codegraph.cmd status <project> --json
```

If the repo changed since the last scan, refresh it:

```powershell
.\bin\codegraph.cmd update <project> --json
```

### 3. Load only the smallest useful slice

- Project overview: `slice --dir <project>`
- Module slice: `slice <module> --with-deps --dir <project>`
- Symbol lookup: `query <symbol> --dir <project> --json`
- Module lookup: `query <module> --module --dir <project> --json`
- Impact analysis: `impact <target> --dir <project> --depth 3 --json`

Prefer these graph queries over loading full source files when the user only needs structure, ownership, or dependency information.

## Routing rules

- New project / architecture overview: `slice --dir <project>`
- Specific module: `slice <module> --with-deps --dir <project>`
- Specific function/class/type/variable: `query <symbol> --dir <project> --json`
- Refactor risk / blast radius: `impact <target> --dir <project> --depth 3 --json`
- Repo changed after graph creation: `update <project> --json`

## MCP option

If the client already supports MCP, prefer the server in `mcp-server/` because it exposes the same operations as structured tools and avoids shell-specific wrappers.
