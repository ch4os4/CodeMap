# CodeMap for GitHub Copilot

这份仓库现在同时保留：

- 原始 Claude Code 插件：`ccplugin/`
- Copilot 专用插件：`copilot-plugin/`
- Copilot marketplace 清单：`.github/plugin/marketplace.json`
- Copilot 仓库指令模板：
  - `.github/copilot-instructions.md`
  - `.github/copilot-instructions.strong.md`
  - `copilot-plugin/templates/copilot-instructions.strong.md`

## 1. VS Code 安装

将以下配置加入 VS Code 用户级 `settings.json`：

```json
{
  "chat.plugins.enabled": true,
  "chat.plugins.paths": {
    "J:\\AI\\CodeMap\\copilot-plugin": true
  },
  "chat.plugins.marketplaces": [
    "github/copilot-plugins",
    "github/awesome-copilot",
    "anthropics/claude-code",
    "killvxk/CodeMap"
  ]
}
```

现成示例文件见：
[settings.json](/J:/AI/CodeMap/copilot-plugin/templates/settings.json)

## 2. 安装 Windows 二进制

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.codemap\bin"
Invoke-WebRequest -Uri https://github.com/killvxk/CodeMap/releases/latest/download/codegraph-x86_64-windows.exe `
  -OutFile "$env:USERPROFILE\.codemap\bin\codegraph-x86_64-windows.exe"
```

默认路径：

```text
C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe
```

## 3. 给目标项目追加 Copilot 指令

推荐将强约束版复制到目标项目：

```text
<workspace>\.github\copilot-instructions.md
```

模板见：
[copilot-instructions.strong.md](/J:/AI/CodeMap/copilot-plugin/templates/copilot-instructions.strong.md)

## 4. 首次使用

在目标项目里先扫描一次：

```powershell
C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe scan .
```

之后常用命令：

```powershell
C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe status .
C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe query handleLogin --dir .
C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe slice --dir .
C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe impact auth --dir .
C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe update .
```

## 5. 何时会自动调用 CodeMap

不能保证 100% 自动，但以下条件会显著提高触发率：

- 使用 VS Code Copilot 的 Agent 模式
- 当前工作区存在 `.codemap/graph.json`
- 当前项目根目录有 `.github/copilot-instructions.md`
- 指令中明确要求结构类问题优先使用 CodeMap

## 6. 当前仓库的 Copilot 专用入口

- 插件根：
  [copilot-plugin](/J:/AI/CodeMap/copilot-plugin)
- Marketplace 清单：
  [marketplace.json](/J:/AI/CodeMap/.github/plugin/marketplace.json)
- 仓库级基础指令：
  [copilot-instructions.md](/J:/AI/CodeMap/.github/copilot-instructions.md)
- 仓库级强约束指令：
  [copilot-instructions.strong.md](/J:/AI/CodeMap/.github/copilot-instructions.strong.md)
