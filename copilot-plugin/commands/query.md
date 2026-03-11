---
description: 在代码图谱中查询函数、类、类型、变量或模块的定义和关联关系
arguments:
  - name: symbol
    description: 要查询的符号名称
    required: true
  - name: type
    description: "过滤类型: function, class, type, variable"
    required: false
---

# CodeMap Query

## 执行步骤

### 1. 执行查询

PowerShell:

```powershell
$codegraph = if (Test-Path "C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe") { "C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe" } else { "codegraph" }
& $codegraph query "{{symbol}}" {{#type}}--type {{type}}{{/type}} --dir .
```

Bash:

```bash
codegraph query "{{symbol}}" {{#type}}--type {{type}}{{/type}} --dir .
```

### 2. 展示结果

向用户总结：

- 符号类型
- 定义位置
- 所属模块
- 主要引用关系
- 相关使用行或依赖方

### 3. 深入查看

仅在需要源码细节时再读取对应文件的精确片段。
