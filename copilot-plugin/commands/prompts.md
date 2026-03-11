---
description: 将 CodeMap 使用规则写入 GitHub Copilot 的仓库指令文件
---

# CodeMap Prompts

将 CodeMap 使用规范写入 `.github/copilot-instructions.md`。

## 执行步骤

### 1. 检测图谱是否存在

PowerShell:

```powershell
if (Test-Path ".codemap/graph.json") { "CODEMAP_EXISTS" } else { "NO_CODEMAP" }
```

Bash:

```bash
test -f .codemap/graph.json && echo "CODEMAP_EXISTS" || echo "NO_CODEMAP"
```

如果不存在，先提示用户执行 `/codemap:scan`。

### 2. 读取项目概览

读取 `.codemap/slices/_overview.json`，提取：

- 项目名
- 文件总数
- 语言分布
- 模块列表

### 3. 生成或更新 `.github/copilot-instructions.md`

写入一段仓库级 Copilot 指令，要求：

- 结构分析优先使用 CodeMap
- 图谱不存在时先扫描
- 代码变更后先更新再分析
- 常用命令示例基于 `codegraph`

如果文件已存在，则幂等更新 CodeMap 段落。
