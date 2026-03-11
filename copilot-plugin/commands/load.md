---
description: 从 .codemap/ 加载项目概览或模块切片到当前会话
arguments:
  - name: target
    description: 模块名或文件路径。不指定则加载项目概览
    required: false
---

# CodeMap Load

从 `.codemap/` 读取已缓存的代码图谱，而不是重新通读整个仓库。

## 执行步骤

### 1. 检查图谱是否存在

PowerShell:

```powershell
if (Test-Path ".codemap/graph.json") { "CODEMAP_EXISTS" } else { "NO_CODEMAP" }
```

Bash:

```bash
test -f .codemap/graph.json && echo "CODEMAP_EXISTS" || echo "NO_CODEMAP"
```

如果不存在，先建议执行 `/codemap:scan`。

### 2. 检查图谱状态

PowerShell:

```powershell
$codegraph = if (Test-Path "C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe") { "C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe" } else { "codegraph" }
& $codegraph status .
```

Bash:

```bash
codegraph status .
```

如果用户刚改过代码，建议先 `/codemap:update`。

### 3. 加载策略

- 无参数：读取 `.codemap/slices/_overview.json`
- 参数是模块名：执行 `slice <module> --with-deps --dir .`
- 参数是文件路径：先确定所属模块，再加载该模块切片

PowerShell:

```powershell
$codegraph = if (Test-Path "C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe") { "C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe" } else { "codegraph" }
& $codegraph slice {{target}} --with-deps --dir .
```

Bash:

```bash
codegraph slice {{target}} --with-deps --dir .
```
