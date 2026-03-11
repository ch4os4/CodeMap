---
description: 增量更新代码图谱，只重新解析变更的文件
---

# CodeMap Update

## 执行步骤

### 1. 执行增量更新

PowerShell:

```powershell
$codegraph = if (Test-Path "C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe") { "C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe" } else { "codegraph" }
& $codegraph update .
```

Bash:

```bash
codegraph update .
```

### 2. 展示变更摘要

向用户报告：

- 新增文件数
- 修改文件数
- 删除文件数
- 更新耗时

### 3. 刷新上下文

如果会话里已经引用过旧图谱，重新加载受影响模块。
