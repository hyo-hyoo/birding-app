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
   ├─ technical-decisions.md
   ├─ frontend-development-plan.md
   ├─ frontend-implementation-guide.md
   ├─ backend-development-plan.md
   └─ database-design.md
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
- `docs/frontend-development-plan.md`：静态前端页面的实施顺序、阶段状态、依赖、验证证据和进度日志；不拥有产品需求、MVP 范围、UI 决定或技术架构。前端开发 Agent 在每个阶段完成后更新，用户验收后再把阶段标记为“已完成”。
- `docs/frontend-implementation-guide.md`：当前 Rails 前端实现、维护和学习入口，集中说明渲染链路、文件职责、CSS、Stimulus、I18n、测试、移动端检查及高保真基线与 Rails 实现差异；不拥有产品需求、MVP 范围、UI 决定、技术架构或阶段进度，也不另行拆出设计系统文档。
- `docs/backend-development-plan.md`：Rails 后端设计与纵向切片的阶段、依赖、状态、验证证据和进度记录；不拥有产品需求、MVP 范围、UI 决定、技术架构或数据库 Schema 细节。后端开发 Agent 按阶段维护；纯工程设计阶段依完成标准、验证证据和升级项处理结果记录完成，用户可见业务阶段仍须用户验收，具体规则见该计划第 3、14 节。
- `docs/database-design.md`：MVP 领域模型、ER 图、物理 Schema、约束、索引、完整性策略和 Migration 切片映射；不决定产品能力、MVP 范围、UI 交互或阶段进度，未确认方案必须保留明确状态。
- `.agents/skills/frontend-design/`：UI 设计任务的第一阶段，用于建立有项目辨识度的视觉方向。
- `.agents/skills/mobile-app-ui-design/`：在视觉方向形成后检查移动端信息层级、操作区域、触控尺寸、状态与整体体验。
- `.agents/skills/project-ui-designer/`：负责 UI/UX 分析、页面与流程设计、原型制作和验证；只读取正式文档作为约束，不直接维护正式文档，并仅在产生实质性 UI 决定时输出一次性交接单。
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
8. 讨论和实施必须区分已确认、暂定、未确认、延后、否决、AI 建议和 observed-only 内容。Agent 的当前角色由用户明确分配的任务和适用的项目级 Skill 判断，不依赖 Codex 对话或窗口名称；读取正式文档也不代表该 Agent 自动成为 Project Maintainer。
9. 非 Project Maintainer Agent 只有在产生实质性正式事实变化时才输出一次性交接单，按 `AGENTS.md` 规定的六个栏目描述事实和确认状态，不自行决定正式文档归属，也不自动调用 `$project-doc-maintainer`。按既有正式文档完成常规工作且没有产生实质变化时，只追加固定的“本轮没有产生需要同步到正式文档的变化。”，不生成空交接单。Project Maintainer 根据交接内容判断状态、正式归属和同步范围后再修改文档。
10. 前端开发 Agent 依据正式需求、MVP、UI 和技术文档执行静态页面实施，并在 `docs/frontend-development-plan.md` 中维护阶段进度与验证证据；该计划不得反向改变上游正式决定。
11. 修改 Rails 前端前，开发 Agent 使用 `docs/frontend-implementation-guide.md` 理解当前代码组织、维护约定和验证方式；指南中的代码现状和差异记录不得反向覆盖上游正式决定。
12. 后端开发 Agent 使用 `docs/backend-development-plan.md` 管理阶段、依赖、状态和验证证据，使用 `docs/database-design.md` 维护领域模型、ER 图、物理 Schema、约束及 Migration 映射。两份文档都必须服从需求、MVP 和技术决策，不得用计划或 Schema 草案反向确认未决产品与技术选择。

## 工具职责

- ChatGPT：用于需求探索、澄清、范围讨论和学习复盘；讨论本身不是正式记录。
- Codex：根据当前明确分配的角色读取代码与正式文档，提出小范围计划，并实施和验证授权范围内的变更。非 Project Maintainer Agent 不因讨论或实现产生决定而自动维护正式文档，而是按 `AGENTS.md` 输出一次性交接单。
- `$project-ui-designer`：负责页面结构、用户流程、交互状态、视觉方向、移动端体验和前端原型；需要视觉设计时先用 `$frontend-design`，再用 `$mobile-app-ui-design`。它不得直接修改正式项目文档，只能输出一次性交接单。
- `$frontend-design` 与 `$mobile-app-ui-design`：作为 `$project-ui-designer` 的专业设计与移动端检查步骤。Skill 中提到的 React、Tailwind、React Native、Flutter 或 SwiftUI 仅是设计或实现示例，不改变本项目默认的 Rails Web 技术方向。
- `$project-doc-maintainer`：只在当前任务明确承担 Project Maintainer 职责，或用户明确要求正式文档维护时调用；它在项目文档或项目级规则变化后检查 Git 变更、文档职责、状态、路径和遗漏，信息不足时列出问题，不编造项目决定。

当当前 Codex 任务被明确分配为 Project Maintainer、UI Designer 或开发 Agent，而用户请求明显属于另一角色时，当前 Agent 应先提醒用户可能发错任务或窗口，并在该轮停止执行，不得静默切换职责。

## 维护检查

修改项目前先按 `AGENTS.md` 阅读核心文档并给出简短计划。修改后运行 `$project-doc-maintainer`，分别判断 `AGENTS.md` 与 `DOCUMENTS-GUIDE.md` 是否达到更新触发条件，展示 diff，并说明每项修改原因。
