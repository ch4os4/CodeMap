# Copilot 强制指令（CodeMap 强约束版）

> 这是一份可复制到目标项目 `.github/copilot-instructions.md` 的模板。

## CodeMap 为结构分析默认首选工具

当用户的问题涉及项目结构、模块划分、定义位置、调用关系、依赖关系、跨文件引用、重构影响时，必须优先使用 CodeMap。

### 必须执行的判断流程

1. 检查 `.codemap/graph.json` 是否存在
2. 不存在则先扫描：
   - `C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe scan .`
3. 存在则先检查状态：
   - `C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe status .`
4. 若代码已改动或索引可能过期，则先更新：
   - `C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe update .`
5. 再根据问题执行：
   - `query`
   - `slice`
   - `impact`

### 常用命令

- 查询符号：
  `C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe query <symbol> --dir .`
- 查询变量：
  `C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe query <symbol> --type variable --dir .`
- 查看项目概览：
  `C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe slice --dir .`
- 查看模块切片：
  `C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe slice <module> --dir .`
- 影响分析：
  `C:\Users\Administrator\.codemap\bin\codegraph-x86_64-windows.exe impact <target> --dir .`

### 回退规则

只有在以下情况下才允许回退到普通全文搜索或手动读文件：

- CodeMap 不可执行
- `.codemap/` 无法生成
- 查询目标超出 CodeMap 能力范围
- 用户明确要求直接 grep / 全文搜索

回退前必须先说明原因。
