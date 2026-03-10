[中文文档](README.zh-CN.md)

[![Release](https://github.com/killvxk/CodeMap/actions/workflows/release.yml/badge.svg)](https://github.com/killvxk/CodeMap/actions/workflows/release.yml)

# CodeMap

AST-based code graph toolkit for MCP clients, Codex/OpenAI skills, and the Rust CLI. Scan your codebase once, persist a structural graph, and load compact slices in future sessions — saving ~95% tokens compared to re-reading all source files.

## Features

- **AST Parsing** — Uses tree-sitter native bindings for accurate structural analysis, no regex guessing
- **Multi-Language** — TypeScript, JavaScript, Python, Go, Rust, Java, C, C++
- **Smart Slicing** — Project overview (~500 tokens) + per-module slices (~2-5k tokens) instead of full source (~200k+)
- **Variable Tracking** — Tracks module-level const/static/let/var declarations, queryable with `--type variable`
- **Line-Level References** — Cross-file references pinpoint import line + usage lines; same-file exported symbols also track usage locations
- **Incremental Updates** — File hash comparison detects changes; only re-parses modified files
- **Impact Analysis** — See what's affected before you refactor
- **Structured JSON Output** — `scan/status/query/update/impact` now support `--json`, making MCP integration stable
- **MCP + Skill Ready** — Use the bundled MCP server or install the repository root as a Codex/OpenAI skill
- **Claude Plugin Compatible** — The original Claude Code plugin remains available for existing users

---

## Origin and Attribution

- Original upstream project: [killvxk/CodeMap](https://github.com/killvxk/CodeMap)
- Original upstream focus: Claude Code plugin workflow via `.claude-plugin/` and `ccplugin/`
- Current repository focus: MCP server, repo-level skill, and generic CLI launchers, while keeping the Claude plugin path as a compatibility mode

## Usage Modes

### Original Upstream Usage

The original project was designed primarily for Claude Code plugin usage:

```text
1. Add marketplace source in Claude Code
2. Install plugin codemap@codemap-plugins
3. Restart Claude Code
4. Use /codemap:scan, /codemap:load, /codemap:update, /codemap:query, /codemap:impact
```

Typical original commands inside Claude Code:

```text
/plugin marketplace add /absolute/path/to/CodeMap
/plugin install codemap@codemap-plugins
/codemap:scan
/codemap:load
/codemap:query handleLogin
```

### Current Project Usage

The current repository is no longer limited to Claude Code. Recommended usage order:

```text
1. MCP server for Codex and any MCP-capable client
2. Repo-level skill for Codex / OpenAI agent environments
3. Generic codegraph CLI launcher for direct shell usage
4. Claude Code plugin only when you specifically want the legacy slash-command workflow
```

Typical current commands:

```bash
# MCP server
cd mcp-server
python -m codemap_mcp.server

# CLI / launcher
bash ./bin/codegraph scan /path/to/project --json
bash ./bin/codegraph query handleLogin --dir /path/to/project --json
```

```powershell
# Windows CLI / launcher
.\bin\codegraph.cmd scan C:\path\to\project --json
.\bin\codegraph.cmd impact auth --dir C:\path\to\project --json
```

For `VS Code + GitHub Copilot`, a one-command installer is also included:

```powershell
.\install-vscode-copilot.cmd C:\path\to\your-workspace
```

It automatically:

```text
1. Creates or reuses mcp-server/.venv
2. Installs the codemap-mcp package
3. Creates or merges .vscode/mcp.json in the target workspace
```

---

## Installation

### Prerequisites

- Python 3.10+ for the MCP server
- Rust toolchain only if you want to build the CLI from source

### Option 1: Run as an MCP Server (Recommended)

#### Fastest path: one-command install for VS Code Copilot

Windows:

```powershell
.\install-vscode-copilot.cmd C:\path\to\your-workspace
```

macOS / Linux:

```bash
bash ./scripts/install-vscode-copilot.sh /path/to/your-workspace
```

The installer writes the CodeMap MCP server into the target workspace `.vscode/mcp.json`.

#### 1. Clone the repository

```bash
git clone https://github.com/killvxk/CodeMap.git
cd CodeMap
```

#### 2. Install the MCP server package

```bash
cd mcp-server
python -m venv .venv
. .venv/bin/activate
pip install -e .
```

Windows PowerShell:

```powershell
cd mcp-server
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e .
```

#### 3. Start the server

```bash
cd mcp-server
python -m codemap_mcp.server
```

The server exposes these MCP tools:

- `scan_project`
- `get_graph_status`
- `load_graph_slice`
- `query_symbol`
- `query_module`
- `update_project`
- `analyze_impact`

#### 4. Example MCP client config

```json
{
  "mcpServers": {
    "codemap": {
      "command": "python",
      "args": ["-m", "codemap_mcp.server"],
      "cwd": "/absolute/path/to/CodeMap/mcp-server"
    }
  }
}
```

### Option 2: Use as a Codex / OpenAI Skill

The repository root now contains `SKILL.md` and `agents/openai.yaml`, so it can be used directly as a local skill.

Typical launcher commands used by the skill:

```powershell
.\bin\codegraph.cmd status <project> --json
.\bin\codegraph.cmd slice <module> --with-deps --dir <project>
```

```bash
bash ./bin/codegraph status <project> --json
bash ./bin/codegraph slice <module> --with-deps --dir <project>
```

### Option 3: Use the Rust CLI / Prebuilt Binary

The root `bin/` launcher **automatically downloads** the platform-specific binary from GitHub Releases to `~/.codemap/bin/` on first command execution. No manual steps required.

Binary lookup order (highest to lowest priority):

| Priority | Location | Description |
|---|---|---|
| 1 | `PATH` | Arch-specific binary installed globally |
| 2 | `~/.codemap/bin/` | User-level dedicated directory (recommended) |
| 3 | `bin/` | Repo-level launcher directory |
| 4 | `rust-cli/target/release/` | Local dev build |
| 5 | Auto-download | Downloads from GitHub Releases to `~/.codemap/bin/` |

```bash
# Manual install example
mkdir -p ~/.codemap/bin
# Linux x64
curl -fSL -o ~/.codemap/bin/codegraph-x86_64-linux \
  https://github.com/killvxk/CodeMap/releases/latest/download/codegraph-x86_64-linux
chmod +x ~/.codemap/bin/codegraph-x86_64-linux

# macOS Apple Silicon
curl -fSL -o ~/.codemap/bin/codegraph-aarch64-macos \
  https://github.com/killvxk/CodeMap/releases/latest/download/codegraph-aarch64-macos
chmod +x ~/.codemap/bin/codegraph-aarch64-macos
```

> Customize the directory via `CODEMAP_HOME` env var (default `~/.codemap`).

After installation, use the launcher directly:

```bash
bash ./bin/codegraph scan /path/to/project --json
bash ./bin/codegraph status /path/to/project --json
bash ./bin/codegraph query handleLogin --dir /path/to/project --json
```

Windows PowerShell:

```powershell
.\bin\codegraph.cmd scan C:\path\to\project --json
.\bin\codegraph.cmd status C:\path\to\project --json
```

### Option 4: Build from Source

Requires Rust toolchain ([rustup.rs](https://rustup.rs)):

```bash
git clone https://github.com/killvxk/CodeMap.git
cd CodeMap/rust-cli
cargo build --release
# Binary at: target/release/codegraph
```

#### GitHub Release Workflow

```bash
# 1. Ensure tests pass
cd rust-cli && cargo test

# 2. Commit, tag, and let CI build & release
cd ..
git add .
git commit -m "release: v0.2.6"
git tag v0.2.6
git push origin main --tags
# GitHub Actions will automatically build for all platforms and create a Release
```

### Option 5: Claude Code Plugin (Compatibility)

The original Claude Code plugin is still available in `ccplugin/` for existing workflows.

Install inside Claude Code:

```
/plugin marketplace add /absolute/path/to/CodeMap
/plugin install codemap@codemap-plugins
```

---

## Project Structure

```
CodeMap/
├── SKILL.md                    # Repo-level Codex/OpenAI skill entry
├── agents/
│   └── openai.yaml             # Skill UI metadata
├── bin/
│   ├── codegraph               # Generic Unix launcher
│   └── codegraph.cmd           # Generic Windows launcher
├── .claude-plugin/
│   └── marketplace.json        # Marketplace manifest
├── ccplugin/                   # Plugin root (CLAUDE_PLUGIN_ROOT)
│   ├── .claude-plugin/
│   │   └── plugin.json         #   Plugin manifest
│   ├── commands/               #   Slash commands
│   │   ├── scan.md             #     /codemap:scan
│   │   ├── load.md             #     /codemap:load
│   │   ├── update.md           #     /codemap:update
│   │   ├── query.md            #     /codemap:query
│   │   ├── impact.md           #     /codemap:impact
│   │   └── prompts.md          #     /codemap:prompts
│   ├── skills/                 #   Auto-triggering skill
│   │   └── codemap/SKILL.md    #     Unified entry, smart routing
│   ├── hooks/                  #   Event hooks
│   │   ├── hooks.json          #     SessionStart auto-detect
│   │   └── scripts/
│   │       └── detect-codemap.sh
│   └── bin/                    #   Binary wrappers
│       ├── codegraph           #     Unix wrapper (auto-discover/download binary)
│       └── codegraph.cmd       #     Windows wrapper
├── mcp-server/                 # Python MCP server
│   ├── pyproject.toml
│   └── codemap_mcp/
│       └── server.py           #     stdio MCP entry
├── rust-cli/                   # Rust CLI source
│   ├── Cargo.toml
│   ├── src/
│   │   ├── main.rs             #   CLI entry (clap)
│   │   ├── scanner.rs          #   Full scan engine
│   │   ├── graph.rs            #   Graph data structures
│   │   ├── differ.rs           #   Incremental update engine
│   │   ├── query.rs            #   Query engine
│   │   ├── slicer.rs           #   Slice generation
│   │   ├── impact.rs           #   Impact analysis
│   │   ├── path_utils.rs       #   Shared path utilities
│   │   ├── traverser.rs        #   File traversal & language detection
│   │   └── languages/          #   Language adapters (8 languages)
│   └── tests/                  #   Integration tests (127 tests)
├── README.md
└── LICENSE                     # MIT
```

---

## CLI Commands

All commands run via `codegraph <command>` (pre-compiled binary, no Node.js required).

| Command | Description |
|---------|-------------|
| `scan <dir>` | Full AST scan, generates `.codemap/` with graph + slices |
| `status [dir]` | Show graph metadata (files, modules, last scan time) |
| `query <symbol>` | Search for functions, classes, types, variables by name |
| `slice [module]` | Output project overview or a specific module slice as JSON |
| `update [dir]` | Incremental update — re-parse only changed files |
| `impact <target>` | Analyze which modules are affected by changing a target |

`scan`, `status`, `query`, `update`, and `impact` also support `--json` for machine-readable output.

### Examples

```bash
# Scan a project
codegraph scan /path/to/project --json

# Check graph status
codegraph status /path/to/project --json

# Query a symbol
codegraph query "handleLogin" --dir /path/to/project --json

# Get module slice with dependencies
codegraph slice auth --with-deps --dir /path/to/project

# Incremental update after code changes
codegraph update /path/to/project --json

# Impact analysis before refactoring
codegraph impact auth --depth 3 --dir /path/to/project --json
```

---

## Claude Code Compatibility

When installed as the legacy Claude Code plugin, the following capabilities remain available:

### Auto-Triggering

The `codemap` skill auto-activates based on conversation context and intelligently routes to the right operation. A `SessionStart` hook also detects `.codemap/` at session start.

### Slash Commands

You can also invoke manually:

| Command | Description |
|-------|------------|
| `/codemap:scan` | Full scan, generate .codemap/ graph |
| `/codemap:load [target]` | Load graph into context (overview/module/file) |
| `/codemap:update` | Incremental update |
| `/codemap:query <symbol>` | Query symbol definitions and call relations |
| `/codemap:impact <target>` | Analyze change impact |
| `/codemap:prompts` | Inject codemap usage rules into project CLAUDE.md |

### Typical Workflow

```
1. First time:        /codemap:scan        → Generate .codemap/ graph
2. New session:       (auto-detected)      → SessionStart hook prompts to load
3. Load overview:     /codemap:load        → Load overview (~500 tokens)
4. Dive into module:  /codemap:load auth   → Load auth module (~2-5k tokens)
5. After changes:     /codemap:update      → Incremental update
6. Before refactor:   /codemap:impact auth → Check impact scope
7. Inject rules:      /codemap:prompts     → Write usage rules to CLAUDE.md
```

---

## Supported Languages

| Language | Extensions | Extracted Structures |
|----------|-----------|---------------------|
| TypeScript | `.ts`, `.tsx` | Functions, imports, exports, classes, interfaces, type aliases, variables (const/let) |
| JavaScript | `.js`, `.jsx`, `.mjs`, `.cjs` | Functions, imports, exports, classes, variables (const/let) |
| Python | `.py` | Functions (decorated), imports, `__all__` exports, classes, module-level variables |
| Go | `.go` | Functions, methods (with receiver), imports, exported names, structs, type specs, variables (var/const) |
| Rust | `.rs` | Functions, impl methods, use declarations, pub exports (incl. const/static), structs, enums, traits, variables (const/static) |
| Java | `.java` | Methods, constructors, imports, public exports, classes, interfaces, enums, static fields |
| C | `.c`, `.h` | Functions, `#include`, non-static exports, structs, enums, typedefs, global variables |
| C++ | `.cpp`, `.cc`, `.cxx`, `.hpp`, `.hh` | Qualified functions (`Class::method`), includes, classes, structs, namespaces, global variables |

---

## Graph Structure

Scanning produces a `.codemap/` directory inside the target project:

```
.codemap/
├── graph.json          # Full structural graph
├── meta.json           # File hashes, timestamps, commit info
└── slices/
    ├── _overview.json  # Compact project overview (~500 tokens)
    ├── auth.json       # Per-module detailed slice
    ├── api.json
    └── ...
```

---

## Tests

```bash
cd rust-cli
cargo test
```

## License

[MIT](LICENSE)

---

## Appendix: Token Efficiency Comparison — CodeMap vs Grep vs LSP

When an AI coding assistant needs to understand code structure, different tools consume vastly different amounts of tokens. Using the function `analyze_impact` as an example:

### Approach 1: Grep + Read (Traditional)

| Step | Operation | Tokens |
|---|---|---|
| 1 | `Grep "analyze_impact"` — search entire project | ~300-500 |
| 2 | `Read impact.rs` — read definition (280 lines) | ~1500-2000 |
| 3 | `Read commands/impact.rs` — read caller | ~400-600 |
| 4 | `Read tests/impact_compat.rs` — read test references | ~800-1200 |
| 5 | Additional Grep to confirm coverage | ~300-500 |
| **Total** | **4-5 tool calls** | **~3000-5000** |

### Approach 2: LSP (find-references)

| Step | Operation | Tokens |
|---|---|---|
| 1 | `find-references` returns 11 locations | ~200 |
| 2 | `Read impact.rs` to understand context | ~1500 |
| 3 | `Read commands/impact.rs` to understand context | ~500 |
| 4 | `Read tests/impact_compat.rs` to understand context | ~800 |
| **Total** | **3-4 tool calls** | **~3000** |

> LSP returns **raw positions** (file:line:column). The AI agent still needs to Read each file to understand whether a reference is an import or a function call.

### Approach 3: CodeMap query

| Step | Operation | Tokens |
|---|---|---|
| 1 | `codegraph query analyze_impact` — single query returns everything | ~150-200 |
| **Total** | **1 tool call** | **~150-200** |

Results are pre-categorized:

```
[function] analyze_impact (rust-cli/src/impact.rs:35)
  signature: analyze_impact(graph, target, max_depth)
  module:    rust-cli
  lines:     35-68
  usedAt:                          ← Same-file calls
    rust-cli/src/impact.rs :211 :228 :236 :245 :253 :261 :271 :278
  importedBy:                      ← Cross-file references
    rust-cli/src/commands/impact.rs:5 (use :5 :37)
    rust-cli/tests/impact_compat.rs:1 (use :1 :17 :24 :31 :42 ...)
```

### Summary

| | Grep + Read | LSP | CodeMap |
|---|---|---|---|
| Tokens | ~3000-5000 | ~3000 | ~150-200 |
| Tool calls | 4-5 | 3-4 | 1 |
| Savings | Baseline | ~30% | **~95%** |
| Requires file reads | Yes | Yes | No |
| Pre-categorized | No | No | Yes |
| Requires running service | No | Yes | No |
| Cross-language unified | No | No | Yes |

> **Key Insight:** LSP is designed for humans — click a reference in the IDE, jump to it, and understand context visually (zero tokens). CodeMap is designed for AI agents — returns pre-computed structural relationships so the agent understands call chains without reading files.
