[English](README.md)

[![Release](https://github.com/killvxk/CodeMap/actions/workflows/release.yml/badge.svg)](https://github.com/killvxk/CodeMap/actions/workflows/release.yml)

# CodeMap

面向 MCP 客户端、Codex/OpenAI skill 和 Rust CLI 的 AST 代码图谱工具。扫描代码库一次，持久化结构图谱，后续会话加载紧凑切片即可恢复上下文——相比重新读取全部源码，节省约 95% token。

## 特性

- **AST 解析** — 使用 tree-sitter 原生绑定进行精确的结构分析，非正则猜测
- **多语言支持** — TypeScript, JavaScript, Python, Go, Rust, Java, C, C++
- **智能切片** — 项目概览 (~500 tokens) + 按模块切片 (~2-5k tokens)，替代全量源码 (~200k+)
- **变量追踪** — 追踪模块级 const/static/let/var 声明，支持按 `--type variable` 查询
- **行号级引用** — 跨文件引用精确到 import 行号 + 使用行号，同文件导出符号也追踪使用位置
- **增量更新** — 基于文件哈希比较检测变更，仅重新解析修改的文件
- **影响分析** — 重构前查看哪些模块会受影响
- **结构化 JSON 输出** — `scan/status/query/update/impact` 已支持 `--json`，便于 MCP 稳定调用
- **MCP + Skill 就绪** — 仓库内置 MCP server，也可直接把仓库根目录作为 Codex/OpenAI skill 使用
- **Claude 插件兼容** — 原有 Claude Code plugin 保留，兼容旧工作流

---

## 原始来源与引用说明

- 原始上游项目：[killvxk/CodeMap](https://github.com/killvxk/CodeMap)
- 原始上游定位：以 Claude Code plugin 工作流为主，入口集中在 `.claude-plugin/` 与 `ccplugin/`
- 当前仓库定位：以 MCP server、仓库级 skill、通用 CLI launcher 为主，同时保留 Claude plugin 兼容模式

## 使用方式总览

### 原始项目使用说明

原始项目主要面向 Claude Code plugin 工作流：

```text
1. 在 Claude Code 中添加 marketplace source
2. 安装 codemap@codemap-plugins
3. 重启 Claude Code
4. 使用 /codemap:scan、/codemap:load、/codemap:update、/codemap:query、/codemap:impact
```

原始典型命令如下：

```text
/plugin marketplace add /absolute/path/to/CodeMap
/plugin install codemap@codemap-plugins
/codemap:scan
/codemap:load
/codemap:query handleLogin
```

### 当前项目使用说明

当前仓库已经不再局限于 Claude Code，推荐使用顺序如下：

```text
1. MCP server：用于 Codex 以及其他支持 MCP 的客户端
2. 仓库级 skill：用于 Codex / OpenAI agent 环境
3. 通用 codegraph CLI launcher：用于直接终端调用
4. Claude Code plugin：仅在需要兼容旧斜杠命令工作流时使用
```

当前典型命令如下：

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

针对 `VS Code + GitHub Copilot`，现在也提供一键安装脚本：

```powershell
.\install-vscode-copilot.cmd C:\path\to\your-workspace
```

它会自动完成三件事：

```text
1. 创建/复用 mcp-server/.venv
2. 安装 codemap-mcp 依赖
3. 在目标工作区生成或合并 .vscode/mcp.json
```

---

## 安装

### 前置条件

- Python 3.10+，用于运行 MCP server
- Rust 工具链仅在你需要从源码构建 CLI 时需要

### 方式一：作为 MCP Server 运行（推荐）

#### 最快方式：给 VS Code Copilot 一键安装

Windows:

```powershell
.\install-vscode-copilot.cmd C:\path\to\your-workspace
```

macOS / Linux:

```bash
bash ./scripts/install-vscode-copilot.sh /path/to/your-workspace
```

安装脚本会把 CodeMap MCP server 写入目标工作区的 `.vscode/mcp.json`。

#### 1. 克隆仓库

```bash
git clone https://github.com/killvxk/CodeMap.git
cd CodeMap
```

#### 2. 安装 MCP server 包

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

#### 3. 启动 server

```bash
cd mcp-server
python -m codemap_mcp.server
```

暴露的 MCP tools:

- `scan_project`
- `get_graph_status`
- `load_graph_slice`
- `query_symbol`
- `query_module`
- `update_project`
- `analyze_impact`

#### 4. MCP 客户端配置示例

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

### 方式二：作为 Codex / OpenAI Skill 使用

仓库根目录已经包含 `SKILL.md` 和 `agents/openai.yaml`，可以直接作为本地 skill 使用。

skill 内通常调用以下命令：

```powershell
.\bin\codegraph.cmd status <project> --json
.\bin\codegraph.cmd slice <module> --with-deps --dir <project>
```

```bash
bash ./bin/codegraph status <project> --json
bash ./bin/codegraph slice <module> --with-deps --dir <project>
```

### 方式三：使用 Rust CLI / 预编译二进制

根目录 `bin/` launcher 会在首次执行时**自动从 GitHub Releases 下载**对应平台的二进制到 `~/.codemap/bin/`，无需手动操作。

二进制查找优先级从高到低：

| 优先级 | 位置 | 说明 |
|---|---|---|
| 1 | `PATH` | 全局安装的架构对应二进制 |
| 2 | `~/.codemap/bin/` | 用户级专用目录（推荐） |
| 3 | `bin/` | 仓库级 launcher 目录 |
| 4 | `rust-cli/target/release/` | 本地开发构建 |
| 5 | 自动下载 | 从 GitHub Releases 下载到 `~/.codemap/bin/` |

```bash
# 手动安装示例
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

> 支持通过环境变量 `CODEMAP_HOME` 自定义目录（默认 `~/.codemap`）。

安装后可直接调用 launcher：

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

### 方式四：从源码构建

需要 Rust 工具链（[rustup.rs](https://rustup.rs)）：

```bash
git clone https://github.com/killvxk/CodeMap.git
cd CodeMap/rust-cli
cargo build --release
# 二进制输出到: target/release/codegraph
```

#### GitHub Release 发布流程

```bash
# 1. 确保测试通过
cd rust-cli && cargo test

# 2. 提交并打 tag，CI 自动构建并发布
cd ..
git add .
git commit -m "release: v0.2.6"
git tag v0.2.6
git push origin main --tags
# GitHub Actions 会自动为所有平台构建并创建 Release
```

### 方式五：Claude Code 插件（兼容模式）

原有 Claude Code plugin 仍然保留在 `ccplugin/`，供已有工作流继续使用。

在 Claude Code 中安装：

```
/plugin marketplace add /absolute/path/to/CodeMap
/plugin install codemap@codemap-plugins
```

---

## 项目结构

```
CodeMap/
├── SKILL.md                    # 仓库级 Codex/OpenAI skill 入口
├── agents/
│   └── openai.yaml             # skill UI 元数据
├── bin/
│   ├── codegraph               # 通用 Unix launcher
│   └── codegraph.cmd           # 通用 Windows launcher
├── .claude-plugin/
│   └── marketplace.json        # 插件市场清单
├── ccplugin/                   # 插件根目录 (CLAUDE_PLUGIN_ROOT)
│   ├── .claude-plugin/
│   │   └── plugin.json         #   插件清单
│   ├── commands/               #   斜杠命令
│   │   ├── scan.md             #     /codemap:scan
│   │   ├── load.md             #     /codemap:load
│   │   ├── update.md           #     /codemap:update
│   │   ├── query.md            #     /codemap:query
│   │   ├── impact.md           #     /codemap:impact
│   │   └── prompts.md          #     /codemap:prompts
│   ├── skills/                 #   自动触发 Skill
│   │   └── codemap/SKILL.md    #     统一入口，智能路由
│   ├── hooks/                  #   事件钩子
│   │   ├── hooks.json          #     SessionStart 自动检测
│   │   └── scripts/
│   │       └── detect-codemap.sh
│   └── bin/                    #   二进制 wrapper
│       ├── codegraph           #     Unix wrapper (自动发现/下载二进制)
│       └── codegraph.cmd       #     Windows wrapper
├── mcp-server/                 # Python MCP server
│   ├── pyproject.toml
│   └── codemap_mcp/
│       └── server.py           #     stdio MCP 入口
├── rust-cli/                   # Rust CLI 源码
│   ├── Cargo.toml
│   ├── src/
│   │   ├── main.rs             #   CLI 入口（clap）
│   │   ├── scanner.rs          #   全量扫描引擎
│   │   ├── graph.rs            #   图谱数据结构
│   │   ├── differ.rs           #   增量更新引擎
│   │   ├── query.rs            #   查询引擎
│   │   ├── slicer.rs           #   切片生成
│   │   ├── impact.rs           #   影响分析
│   │   ├── path_utils.rs       #   共享路径工具函数
│   │   ├── traverser.rs        #   文件遍历与语言检测
│   │   └── languages/          #   语言适配器 (8 种)
│   └── tests/                  #   集成测试 (127 tests)
├── README.md
└── LICENSE                     # MIT
```

---

## CLI 命令

所有命令通过 `codegraph <command>` 运行（预编译二进制，无需 Node.js）。

| 命令 | 描述 |
|---------|-------------|
| `scan <dir>` | 全量 AST 扫描，生成 `.codemap/` 图谱和切片 |
| `status [dir]` | 显示图谱元信息（文件数、模块、上次扫描时间） |
| `query <symbol>` | 按名称搜索函数、类、类型、变量 |
| `slice [module]` | 输出项目概览或指定模块切片（JSON） |
| `update [dir]` | 增量更新——仅重新解析变更的文件 |
| `impact <target>` | 分析修改目标会影响哪些模块 |

`scan`、`status`、`query`、`update`、`impact` 额外支持 `--json` 机器可读输出。

### 示例

```bash
# 扫描项目
codegraph scan /path/to/project --json

# 检查图谱状态
codegraph status /path/to/project --json

# 查询符号
codegraph query "handleLogin" --dir /path/to/project --json

# 获取模块切片（含依赖）
codegraph slice auth --with-deps --dir /path/to/project

# 增量更新
codegraph update /path/to/project --json

# 影响分析
codegraph impact auth --depth 3 --dir /path/to/project --json
```

---

## Claude Code 兼容能力

作为旧版 Claude Code plugin 安装后，以下能力仍可继续使用：

### 自动触发

`codemap` skill 会根据对话上下文自动激活，智能判断该执行哪个操作。同时 `SessionStart` hook 会在每次会话开始时自动检测 `.codemap/` 是否存在并提示。

### 斜杠命令

也可以手动调用：

| 命令 | 描述 |
|-------|------------|
| `/codemap:scan` | 全量扫描项目，生成 .codemap/ 图谱 |
| `/codemap:load [target]` | 加载图谱到上下文（概览/模块/文件） |
| `/codemap:update` | 增量更新图谱 |
| `/codemap:query <symbol>` | 查询符号定义和调用关系 |
| `/codemap:impact <target>` | 分析变更影响范围 |
| `/codemap:prompts` | 将 codemap 使用规范注入项目 CLAUDE.md |

### 典型工作流

```
1. 首次使用:     /codemap:scan        → 生成 .codemap/ 图谱
2. 新会话开始:   (自动检测)            → SessionStart hook 提示加载
3. 加载概览:     /codemap:load        → 加载概览 (~500 tokens)
4. 深入模块:     /codemap:load auth   → 加载 auth 模块 (~2-5k tokens)
5. 代码修改后:   /codemap:update      → 增量更新图谱
6. 重构前:       /codemap:impact auth → 查看影响范围
7. 注入规范:     /codemap:prompts     → 写入使用规范到 CLAUDE.md
```

---

## 支持的语言

| 语言 | 扩展名 | 提取结构 |
|----------|-----------|---------------------|
| TypeScript | `.ts`, `.tsx` | 函数、导入、导出、类、接口、类型别名、变量（const/let） |
| JavaScript | `.js`, `.jsx`, `.mjs`, `.cjs` | 函数、导入、导出、类、变量（const/let） |
| Python | `.py` | 函数（含装饰器）、导入、`__all__` 导出、类、模块级变量 |
| Go | `.go` | 函数、方法（含接收者）、导入、导出名、结构体、类型声明、变量（var/const） |
| Rust | `.rs` | 函数、impl 方法、use 声明、pub 导出（含 const/static）、结构体、枚举、trait、变量（const/static） |
| Java | `.java` | 方法、构造器、导入、public 导出、类、接口、枚举、静态字段 |
| C | `.c`, `.h` | 函数、`#include`、非 static 导出、结构体、枚举、typedef、全局变量 |
| C++ | `.cpp`, `.cc`, `.cxx`, `.hpp`, `.hh` | 限定函数名（`Class::method`）、include、类、结构体、命名空间、全局变量 |

---

## 图谱结构

扫描后在目标项目内生成 `.codemap/` 目录：

```
.codemap/
├── graph.json          # 完整结构图谱
├── meta.json           # 文件哈希、时间戳、提交信息
└── slices/
    ├── _overview.json  # 紧凑项目概览 (~500 tokens)
    ├── auth.json       # 按模块的详细切片
    ├── api.json
    └── ...
```

---

## 测试

```bash
cd rust-cli
cargo test
```

## 许可证

[MIT](LICENSE)

---

## 附录：CodeMap vs Grep vs LSP — Token 效率对比

AI 编码助手理解代码结构时，不同工具的 token 消耗差异显著。以查询函数 `analyze_impact` 的定义和完整调用关系为例：

### 方式一：Grep + Read（传统方式）

| 步骤 | 操作 | Token 消耗 |
|---|---|---|
| 1 | `Grep "analyze_impact"` 全项目搜索 | ~300-500 |
| 2 | `Read impact.rs` 查看定义（280 行） | ~1500-2000 |
| 3 | `Read commands/impact.rs` 查看调用方 | ~400-600 |
| 4 | `Read tests/impact_compat.rs` 查看测试引用 | ~800-1200 |
| 5 | 可能还需额外 Grep 确认无遗漏 | ~300-500 |
| **合计** | **4-5 次工具调用** | **~3000-5000** |

### 方式二：LSP（find-references）

| 步骤 | 操作 | Token 消耗 |
|---|---|---|
| 1 | `find-references` 返回 11 个位置 | ~200 |
| 2 | `Read impact.rs` 理解引用上下文 | ~1500 |
| 3 | `Read commands/impact.rs` 理解引用上下文 | ~500 |
| 4 | `Read tests/impact_compat.rs` 理解引用上下文 | ~800 |
| **合计** | **3-4 次工具调用** | **~3000** |

> LSP 返回的是**裸位置**（file:line:column），AI agent 拿到位置后仍需 Read 文件才能理解每个引用是 import 还是函数调用。

### 方式三：CodeMap query

| 步骤 | 操作 | Token 消耗 |
|---|---|---|
| 1 | `codegraph query analyze_impact` — 一次返回全部 | ~150-200 |
| **合计** | **1 次工具调用** | **~150-200** |

返回结果已预分类：

```
[function] analyze_impact (rust-cli/src/impact.rs:35)
  signature: analyze_impact(graph, target, max_depth)
  module:    rust-cli
  lines:     35-68
  usedAt:                          ← 同文件调用
    rust-cli/src/impact.rs :211 :228 :236 :245 :253 :261 :271 :278
  importedBy:                      ← 跨文件引用
    rust-cli/src/commands/impact.rs:5 (use :5 :37)
    rust-cli/tests/impact_compat.rs:1 (use :1 :17 :24 :31 :42 ...)
```

### 对比总结

| | Grep + Read | LSP | CodeMap |
|---|---|---|---|
| Token 消耗 | ~3000-5000 | ~3000 | ~150-200 |
| 工具调用次数 | 4-5 | 3-4 | 1 |
| 节省比例 | 基准 | ~30% | **~95%** |
| 需要 Read 文件 | 是 | 是 | 否 |
| 结果预分类 | 否 | 否 | 是 |
| 需要运行服务 | 否 | 是 | 否 |
| 跨语言统一 | 否 | 否 | 是 |

> **核心差异：** LSP 为人设计——人在 IDE 中点击引用即可跳转，用眼睛理解上下文，不消耗 token。CodeMap 为 AI agent 设计——返回预计算的结构化关系，agent 无需再 Read 文件即可理解调用链。
