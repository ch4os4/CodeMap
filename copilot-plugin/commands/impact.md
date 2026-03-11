---
description: 分析修改某个模块或文件的影响范围
arguments:
  - name: target
    description: 要分析的模块名或文件路径
    required: true
  - name: depth
    description: 依赖追踪深度，默认 3
    required: false
---

# CodeMap Impact

## 执行步骤

### 1. 执行影响分析

PowerShell:

```powershell
$codegraph = if (Test-Path "C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe") { "C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe" } else { "codegraph" }
& $codegraph impact "{{target}}" --depth {{depth:-3}} --dir .
```

Bash:

```bash
codegraph impact "{{target}}" --depth {{depth:-3}} --dir .
```

### 2. 展示影响范围

向用户报告：

- 目标模块或文件
- 直接依赖方
- 传递依赖方
- 受影响文件数量
- 风险较高的依赖链
