# 观鸟 Web App｜项目文档指南

本文档说明项目文档的结构、职责和维护流程。仓库中的文档是正式记录；聊天内容只有在结论得到确认并写入对应文档后，才成为项目事实。

## 当前结构

```text
birding-app/
├─ AGENTS.md
├─ DOCUMENTS-GUIDE.md
├─ .agents/
│  └─ skills/
│     ├─ frontend-design/
│     ├─ mobile-app-ui-design/
│     ├─ project-ui-designer/
│     └─ project-doc-maintainer/
├─ prototype/
│  ├─ low-fidelity.html
│  ├─ assets/
│  │  └─ app-logo-preview.png
│  └─ experiments/
│     ├─ visual-direction-comparison.html
│     └─ high-fidelity-baseline.html
└─ docs/
   ├─ current-status.md
   ├─ project-overview.md
   ├─ idea-dump.md
   ├─ requirements.md
   ├─ mvp-scope.md
   ├─ ui-design.md
   └─ technical-decisions.md
```

`docs/technical-decisions.md` 已创建，用于记录已确认的技术路线、实施边界和仍需实施验证的事项。

## 文档职责

- `AGENTS.md`：长期适用的项目级 agent 工作规则、必读材料、测试与交付要求。普通功能需求变化不在这里重复记录。
- `DOCUMENTS-GUIDE.md`：重要文档清单、职责、状态和信息流。重要文档新增、删除、移动、改名或职责变化时更新。
- `docs/current-status.md`：当前阶段、已确认状态、开放问题、下一步和当前禁止事项。新对话或任务应先阅读。
- `docs/project-overview.md`：长期稳定的产品方向、目标用户、技术学习主线和协作原则。
- `docs/idea-dump.md`：未确认想法、研究方向、风险和后续候选。内容不得自动升级为需求或开发任务。
- `docs/requirements.md`：已确认的正式产品需求，以及明确标记的待确认需求问题。
- `docs/mvp-scope.md`：当前版本明确纳入、暂定、未决定和排除的范围及完成标准。
- `docs/ui-design.md`：页面清单、用户流程、导航、组件、页面状态、低保真与视觉原型位置、正式高保真实现基线、Logo 状态、适配边界和 UI 未决问题；原型中的业务示例数据不自动成为正式需求。
- `docs/technical-decisions.md`：已确认的重要技术选择、背景、理由和影响；仅在存在正式决定时创建和更新。
- `.agents/skills/frontend-design/`：UI 设计任务的第一阶段，用于建立有项目辨识度的视觉方向。
- `.agents/skills/mobile-app-ui-design/`：在视觉方向形成后检查移动端信息层级、操作区域、触控尺寸、状态与整体体验。
- `.agents/skills/project-ui-designer/`：负责 UI/UX 分析、页面与流程设计、原型制作和验证；只读取正式文档作为约束，不直接维护正式文档，并在产生实质性 UI 决定时输出一次性交接单。
- `.agents/skills/project-doc-maintainer/`：项目文档或项目级规则变化后，检查文档体系一致性并维护本指南与 `AGENTS.md`。
- `prototype/low-fidelity.html`：当前低保真页面、流程和状态核对原型；不作为需求确认依据。
- `prototype/experiments/visual-direction-comparison.html`：B′ 形成过程中的单页视觉实验记录，不承担正式实现基线职责。
- `prototype/experiments/high-fidelity-baseline.html`：已确认的 B′ 完整 MVP 高保真页面实现基线，覆盖主要页面、账户流程状态、设计系统和 Rails 前端组件参考；其中的业务示例数据不构成正式需求，具体微交互可在不改变整体视觉方向的前提下适配。
- `prototype/assets/app-logo-preview.png`：用户确认的第三版正式 App Logo；具体应用位置、尺寸、安全边距、投影、响应式适配和衍生图标仍由 UI 设计与实现验证确定。

## 信息流

1. 将探索性内容记录在 `docs/idea-dump.md`，保持“未确认”状态。
2. 只有在用户明确确认后，才把产品决定写入 `docs/requirements.md`。
3. 将当前版本的纳入、排除和完成标准同步到 `docs/mvp-scope.md`。
4. 用 `docs/current-status.md` 汇总当前阶段、开放问题和下一步，但不得覆盖需求或 MVP 文档中的正式结论。
5. 将长期稳定的方向写入 `docs/project-overview.md`；将已确认的重要技术选择写入 `docs/technical-decisions.md`。
6. 当文档结构、全局规则或工具职责变化时，更新 `DOCUMENTS-GUIDE.md` 或 `AGENTS.md`。
7. 将页面清单、用户流程、导航、组件、视觉实验状态、正式高保真实现基线和 UI 未决问题写入 `docs/ui-design.md`；只有用户明确确认的视觉层内容才能成为实现基线，原型业务示例不得覆盖正式需求或 MVP 边界。
8. UI Designer 只在对话中输出一次性交接单；Project Maintainer 判断交接内容的状态、正式归属和同步范围后再修改文档。

## 工具职责

- ChatGPT：用于需求探索、澄清、范围讨论和学习复盘；讨论本身不是正式记录。
- Codex：读取代码与正式文档，提出小范围计划，实施和验证变更，并维护受变更影响的项目文档。
- `$project-ui-designer`：负责页面结构、用户流程、交互状态、视觉方向、移动端体验和前端原型；需要视觉设计时先用 `$frontend-design`，再用 `$mobile-app-ui-design`。它不得直接修改正式项目文档，只能输出一次性交接单。
- `$frontend-design` 与 `$mobile-app-ui-design`：作为 `$project-ui-designer` 的专业设计与移动端检查步骤。Skill 中提到的 React、Tailwind、React Native、Flutter 或 SwiftUI 仅是设计或实现示例，不改变本项目默认的 Rails Web 技术方向。
- `$project-doc-maintainer`：在项目文档或项目级规则变化后，检查 Git 变更、文档职责、状态、路径和遗漏；信息不足时列出问题，不编造项目决定。

当当前 Codex 任务被明确分配为 Project Maintainer、UI Designer 或开发 Agent，而用户请求明显属于另一角色时，当前 Agent 应先提醒用户可能发错任务或窗口，并在该轮停止执行，不得静默切换职责。

## 维护检查

修改项目前先按 `AGENTS.md` 阅读核心文档并给出简短计划。修改后运行 `$project-doc-maintainer`，分别判断 `AGENTS.md` 与 `DOCUMENTS-GUIDE.md` 是否达到更新触发条件，展示 diff，并说明每项修改原因。
