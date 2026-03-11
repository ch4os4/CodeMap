---
description: 全量扫描项目代码，生成 AST 结构化图谱到 .codemap/ 目录
arguments:
  - name: dir
    description: 要扫描的目录路径，默认为当前目录
    required: false
---

# CodeMap Scan

使用 CodeMap 生成当前项目的结构化代码图谱。

## 执行步骤

### 1. 解析可执行文件路径

优先使用以下任一可执行文件：

- Windows: `C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe`
- 任意平台: `codegraph`（如果已加入 `PATH`）

### 2. 检查图谱是否已存在

PowerShell:

```powershell
if (Test-Path ".codemap/graph.json") { "CODEMAP_EXISTS" } else { "NO_CODEMAP" }
```

Bash:

```bash
test -f .codemap/graph.json && echo "CODEMAP_EXISTS" || echo "NO_CODEMAP"
```

如果已存在，先提醒用户已有图谱，建议优先使用增量更新。只有用户明确要求重新全量扫描时才覆盖重建。

### 3. 执行扫描

PowerShell:

```powershell
$codegraph = if (Test-Path "C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe") { "C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe" } else { "codegraph" }
& $codegraph scan {{dir:-.}}
```

Bash:

```bash
codegraph scan {{dir:-.}}
```

### 4. 展示扫描摘要

读取 `.codemap/slices/_overview.json`，向用户总结：

- 项目名
- 源文件数与语言分布
- 主要模块列表
- 入口文件和模块依赖概览

### 5. 提示后续操作

- `/codemap:load` 加载项目概览
- `/codemap:query <symbol>` 查询符号
- `/codemap:update` 增量更新图谱
- `/codemap:impact <target>` 分析影响范围
