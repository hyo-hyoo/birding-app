# 观鸟 Web App｜项目文档指南

本文档说明项目文档的结构、职责和维护流程。仓库中的文档是正式记录；聊天内容只有在结论得到确认并写入对应文档后，才成为项目事实。

## 当前结构

```text
birding-app/
├─ AGENTS.md
├─ DOCUMENTS-GUIDE.md
├─ .agents/
│  └─ skills/
│     └─ project-doc-maintainer/
└─ docs/
   ├─ current-status.md
   ├─ project-overview.md
   ├─ idea-dump.md
   ├─ requirements.md
   ├─ mvp-scope.md
   └─ ui-design.md
```

`docs/technical-decisions.md` 当前尚未创建；出现第一项已确认的重要技术或架构决定时再创建，不得用未决定的方案占位。

## 文档职责

- `AGENTS.md`：长期适用的项目级 agent 工作规则、必读材料、测试与交付要求。普通功能需求变化不在这里重复记录。
- `DOCUMENTS-GUIDE.md`：重要文档清单、职责、状态和信息流。重要文档新增、删除、移动、改名或职责变化时更新。
- `docs/current-status.md`：当前阶段、已确认状态、开放问题、下一步和当前禁止事项。新对话或任务应先阅读。
- `docs/project-overview.md`：长期稳定的产品方向、目标用户、技术学习主线和协作原则。
- `docs/idea-dump.md`：未确认想法、研究方向、风险和后续候选。内容不得自动升级为需求或开发任务。
- `docs/requirements.md`：已确认的正式产品需求，以及明确标记的待确认需求问题。
- `docs/mvp-scope.md`：当前版本明确纳入、暂定、未决定和排除的范围及完成标准。
- `docs/ui-design.md`：页面清单、用户流程、导航、组件、页面状态、低保真原型位置和 UI 未决问题；原型内容不自动成为正式需求。
- `docs/technical-decisions.md`：已确认的重要技术选择、背景、理由和影响；仅在存在正式决定时创建和更新。
- `.agents/skills/project-doc-maintainer/`：项目文档或项目级规则变化后，检查文档体系一致性并维护本指南与 `AGENTS.md`。

## 信息流

1. 将探索性内容记录在 `docs/idea-dump.md`，保持“未确认”状态。
2. 只有在用户明确确认后，才把产品决定写入 `docs/requirements.md`。
3. 将当前版本的纳入、排除和完成标准同步到 `docs/mvp-scope.md`。
4. 用 `docs/current-status.md` 汇总当前阶段、开放问题和下一步，但不得覆盖需求或 MVP 文档中的正式结论。
5. 将长期稳定的方向写入 `docs/project-overview.md`；将已确认的重要技术选择写入 `docs/technical-decisions.md`。
6. 当文档结构、全局规则或工具职责变化时，更新 `DOCUMENTS-GUIDE.md` 或 `AGENTS.md`。
7. 将页面清单、用户流程、导航、组件和 UI 未决问题写入 `docs/ui-design.md`，但不得用原型内容覆盖正式需求或 MVP 边界。

## 工具职责

- ChatGPT：用于需求探索、澄清、范围讨论和学习复盘；讨论本身不是正式记录。
- Codex：读取代码与正式文档，提出小范围计划，实施和验证变更，并维护受变更影响的项目文档。
- `$project-doc-maintainer`：在项目文档或项目级规则变化后，检查 Git 变更、文档职责、状态、路径和遗漏；信息不足时列出问题，不编造项目决定。

## 维护检查

修改项目前先按 `AGENTS.md` 阅读核心文档并给出简短计划。修改后运行 `$project-doc-maintainer`，分别判断 `AGENTS.md` 与 `DOCUMENTS-GUIDE.md` 是否达到更新触发条件，展示 diff，并说明每项修改原因。
