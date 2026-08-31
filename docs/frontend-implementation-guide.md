# 观鸟 Web App｜前端实现指南

> 文档性质：Rails 前端实现、维护与学习指南<br>
> 当前适用阶段：静态前端 14／14 已验收，后端阶段 2～5 已交付，阶段 6 真实业务接入尚未开始<br>
> 最近核对日期：2026-08-31<br>
> 正式视觉基线：`prototype/experiments/high-fidelity-baseline.html`

## 1. 文档目的

本文档说明当前 Rails 前端是怎样组织和运行的，帮助后续开发者：

- 找到一个页面、组件、样式、交互或文案对应的文件；
- 理解 Rails View、ERB、Partial、I18n、Turbo 和 Stimulus 在本项目中的分工；
- 在不改变正式产品范围和 UI 方向的前提下扩展页面；
- 区分正式决定、当前实现和仍待确认的设计；
- 使用一致的方法检查桌面端、移动端、可访问性和前端交互。

本文档兼顾项目维护和 Rails 学习，但不承担以下职责：

- 不定义产品能力或业务规则；
- 不决定 MVP 范围或验收标准；
- 不替代正式 UI 设计文档或高保真实现基线；
- 不新增后端架构决定；
- 不记录阶段验收进度；
- 不作为独立设计系统文档。

发生冲突时，按以下正式依据判断：

| 内容 | 正式依据 |
| --- | --- |
| 产品能力和业务规则 | `docs/requirements.md` |
| 当前版本范围和验收标准 | `docs/mvp-scope.md` |
| 页面、流程、状态和 UI 规则 | `docs/ui-design.md` |
| 技术路线和架构决定 | `docs/technical-decisions.md` |
| 当前项目状态 | `docs/current-status.md` |
| 阶段任务和验收进度 | `docs/frontend-development-plan.md` |
| 后端接入阶段与依赖 | `docs/backend-development-plan.md` |
| 领域模型和持久化设计 | `docs/database-design.md` |
| 未确认想法 | `docs/idea-dump.md`，不得作为开发依据 |

## 2. 信息状态标记

本文档使用以下状态，避免把代码现状或建议误认为正式需求：

| 标记 | 含义 |
| --- | --- |
| 已确认 | 用户已经明确确认，且有对应正式依据 |
| 暂定 | 当前可以据此继续工作，但还可能在验收或设计讨论后调整 |
| 未确认 | 已提出但尚未得到用户决定 |
| 已延后 | 已明确不在当前阶段实现 |
| 已否决 | 已明确不采用 |
| AI 建议 | 仅由 AI 提出，尚不是项目决定 |
| 仅代码现状 | 当前代码或原型中可以观察到，但不能单独证明产品决定 |

代码与正式文档不一致时，不应直接用代码反向修改需求。先确认差异属于有意适配、未完成实现、历史遗留还是新的待决问题，再交由对应角色处理。

## 3. 当前前端范围

### 3.1 已确认的技术边界

当前正式页面采用：

- Rails Views；
- ERB；
- HTML；
- CSS；
- Turbo；
- Stimulus；
- 少量普通 JavaScript；
- Rails I18n。

当前不引入 Vue、React、Tailwind、独立 SPA、独立前端仓库或新的前端构建体系。

### 3.2 当前代码处于什么状态

当前页面是 Rails 内的静态前端预览：

- 14／14 个计划页面或流程状态及阶段 1～7 已通过用户验收；该验收只证明静态页面、双语、局部交互、代表性错误效果、可访问性和多尺寸回归完成；

- 已有 Rails 路由、Controller、View、Partial、CSS、Stimulus 和 I18n；
- 页面状态由查询参数、ERB 示例数据和浏览器内存共同模拟；
- 已有数据库设计基线，但没有已实施的业务 Model、Migration、业务 Schema、认证或持久化流程；
- 刷新页面会重置浏览器内的交互状态；
- 账户表单只展示结构和流程，不会提交真实数据；
- 预览路由只在 Rails 本地环境中开放。

这一状态是实现条件，不代表未来正式业务页面仍应使用静态数据。

### 3.3 静态账户页接入真实后端的边界

正式接入后，账户页面继续使用 Rails 服务端渲染，数据流应变为：

```text
真实表单提交
  → 正式 Route 与 Controller
  → Model、令牌、限流或 Session 规则
  → 服务器决定成功或失败状态
  → 重新渲染表单，或重定向到结果页面
```

接入时遵守以下边界：

- 正式账户表单使用 Rails 表单能力并具有真实 `action`、HTTP method 和 CSRF 保护；当前 `data-static-preview="true"` 表单不能直接充当业务端点；
- 登录、注册和验证结果必须由服务器数据决定。`state` query parameter 只用于本地静态预览，不得控制真实登录结果、验证状态或邮件发送结果；
- 注册校验失败时，服务器返回可重新渲染的字段错误，保留邮箱并清空密码和确认密码；密码不得回填到 HTML；
- 用户可直接修正的问题使用字段错误；邮箱不存在或密码错误使用同一页面级通用提示。密码正确但账户未验证时可以明确提示验证并提供重发入口，但不得建立 Session；
- 重复注册不创建第二个账户，也不由注册动作自动重发邮件；页面提供登录和重新验证入口，但不泄露账户验证状态；
- 注册已经创建未验证账户但邮件任务未入队时，结果页说明账户已创建、邮件暂未发出，并复用统一重发入口；入队失败不得让仍有效的旧链接失效，入队后投递失败则不恢复旧链接；
- 邮箱验证链接首次 GET 只由服务器检查并显示带脱敏邮箱的确认页；用户确认 POST 时服务器再次校验并完成验证。验证成功、链接过期、无效、已使用、已被替换和已经验证等状态由 Controller 选择结果页面或 `_result_card`；
- 邮件服务内部故障只向页面提供通用提示，具体异常写入服务器日志；限流反馈同样不得泄露邮箱是否存在；
- 主动登录成功进入观察历史；从受保护页面进入登录时，只能返回服务器验证过的站内相对路径，外部或无效地址回到观察历史；
- 退出登录提交到正式退出端点，只结束当前浏览器对应的当前 Session，并清理当前 Cookie；页面不增加“记住我”选项；
- 忘记密码链接有效期为 30 分钟，只有最新链接有效且只能使用一次；重置成功后结束全部会话。已登录修改密码成功后保留当前会话并结束其他会话；
- 真实后端页面优先复用现有布局、账户 Partial、`_form_errors` 和 `_result_card`，不为后端接入另建视觉体系。

**已确认邮件反馈边界**：新令牌保存且邮件任务实际入队成功才切换链接；入队不等于送达，结果页面不能承诺邮件必达。入队失败保留旧链接，后续投递失败通过重试或重发恢复而不恢复旧链接；失效令牌清理后的链接统一显示无效。正式规则见 `technical-decisions.md` 6.1、6.8 节；事务和 Job 协作设计见 `database-design.md` 14.3 节，仍须在后端实施时验证。

**暂定实施边界**：静态预览路由是否长期保留，由开发 Agent 在不影响正式路由的前提下判断。

### 3.4 观察记录与鸟种识别接入真实后端的边界

- 新建页和预览都不创建 Observation。正式保存必须由服务器从当前登录用户建立记录，重新校验轮廓、部位、确定程度和行动位置等输入，并以一次事务保存 Observation、部位印象和行动位置；
- 预览请求只把当前未保存表单交给服务器生成 SVG 与摘要，不写数据库，也不能把预览成功当作正式保存通过；
- 保存失败时继续渲染用户当前表单和字段错误，数据库不得呈现部分成功；首次保存成功后重定向到详情页，刷新详情页不会重复提交；
- 编辑观察与鸟种识别是两个独立保存范围。页面存在尚未保存的候选删除或最终鸟名修改时，应先要求保存或放弃，再允许添加、确认或撤销等立即生效命令；
- 所有记录和子对象都必须从当前用户已授权的 Observation 取得。隐藏按钮、浏览器中的 owner 字段或 Stimulus 状态不能替代服务器授权；
- 同一范围发生并发修改时，后端必须拒绝旧页面静默覆盖新结果；前端负责把冲突反馈清楚展示，并允许用户重新载入或重新操作。具体冲突控件和文案在机制确定后再落实。
- 文本长度遵守 `requirements.md` 的鸟名与描述／行为上限；前端提示不能代替服务器校验，超长应返回字段错误，不截断原输入。当前静态表单不能作为这些业务校验已实现的证据。

## 4. 从网址到页面：Rails 渲染链路

对有 Java 或 Spring 经验的开发者，可以把当前链路理解为：

```text
浏览器请求
  → config/routes.rb
  → FrontendPreviewsController 的 action
  → app/views/frontend_previews/*.html.erb
  → shared 或 frontend_previews 下的 Partial
  → application.html.erb 布局
  → CSS + importmap 中加载的 Turbo/Stimulus
```

近似对应关系如下：

| Rails 概念 | 可以怎样理解 | 当前项目中的作用 |
| --- | --- | --- |
| Route | Spring MVC 的路由映射 | 把 `/previews/...` 指向 Controller action |
| Controller action | 接收请求的方法 | 当前主要提供页面入口和 locale 环境 |
| View | 服务端模板 | 用 ERB 生成最终 HTML |
| Partial | 可复用模板片段 | 复用页头、底部导航、结果卡片等结构 |
| Layout | 页面外壳 | 统一 `<html>`、`<head>`、资源和 `.app-shell` |
| Helper/path helper | 服务端模板辅助方法 | 生成带 locale 的 Rails 路径和翻译文本 |
| Stimulus controller | 页面局部交互控制器 | 管理选择、预览、弹窗和未保存状态；不是后端 Controller |

当前 `FrontendPreviewsController` 使用 `around_action` 设置预览语言。只有与 `I18n.available_locales` 完全匹配的 locale 才会使用，否则回退到默认日语。

## 5. 文件与职责地图

```text
app/
├─ controllers/
│  └─ frontend_previews_controller.rb   # 静态预览 action 与 locale
├─ views/
│  ├─ layouts/application.html.erb      # 全站 HTML 外壳与资源入口
│  ├─ frontend_previews/                # 各预览页面及页面专用 Partial
│  └─ shared/                           # 跨页面复用的 View Partial
├─ assets/stylesheets/application.css   # 当前全部前端样式和视觉变量
└─ javascript/
   ├─ application.js                    # Turbo 与 Stimulus 入口
   └─ controllers/                      # Stimulus controllers

config/
├─ routes.rb                            # 本地预览路由
├─ importmap.rb                         # JavaScript 依赖映射
└─ locales/
   ├─ zh-CN.yml                         # 简体中文界面文案
   └─ ja.yml                            # 日语界面文案

test/
├─ integration/frontend_previews_test.rb # HTML、路由、语言和页面契约
└─ system/                               # 浏览器交互流程
```

### 5.1 页面入口

当前预览路由都位于 `Rails.env.local?` 条件内，不应据此推断正式生产路由：

| 路径 | View/action | 当前用途 |
| --- | --- | --- |
| `/previews/login` | `login` | 登录页静态预览 |
| `/previews/register` | `register` | 注册页静态预览 |
| `/previews/verification-sent` | `verification_sent` | 验证邮件已发送 |
| `/previews/verification-success` | `verification_success` | 邮箱验证成功 |
| `/previews/reset-request` | `reset_request` | 请求重置密码 |
| `/previews/reset-password` | `reset_password` | 设置新密码 |
| `/previews/reset-success` | `reset_success` | 密码重置成功 |
| `/previews/history-empty` | `history_empty` | 空观察历史 |
| `/previews/history` | `history` | 非空观察历史与三种识别状态 |
| `/previews/outline` | `outline` | 两阶段鸟类轮廓选择 |
| `/previews/editor` | `editor` | 观察印象记录编辑器 |
| `/previews/detail?state=...` | `detail` | 待确认、候选中、已确认详情 |
| `/previews/settings` | `settings` | 设置、语言和账户入口 |
| `/previews/change-password` | `change_password` | 登录后修改密码静态表单 |

常用本地浏览方式：

```text
http://127.0.0.1:3100/previews/history?locale=zh-CN
http://127.0.0.1:3100/previews/login?locale=zh-CN&state=invalid_credentials
http://127.0.0.1:3100/previews/register?locale=ja&state=password_mismatch
http://127.0.0.1:3100/previews/editor?locale=zh-CN
http://127.0.0.1:3100/previews/detail?locale=zh-CN&state=confirmed
http://127.0.0.1:3100/previews/settings?locale=zh-CN
http://127.0.0.1:3100/previews/change-password?locale=zh-CN
```

`locale` 当前支持 `zh-CN` 和 `ja`。`detail`、`login` 和 `register` 的 `state` 只用于选择静态预览状态，不是正式数据接口，也不执行服务器校验。

## 6. Layout、页面与 Partial 的边界

### 6.1 Layout

`app/views/layouts/application.html.erb` 负责：

- 设置 `<html lang>`；
- 输出页面 title、viewport、主题色和 color scheme；
- 引入 `app` stylesheet；
- 引入 importmap JavaScript；
- 提供 `.app-shell` 页面根容器。

页面特有内容应留在具体 View 中，不要把某个流程的标题、按钮或状态放进 Layout。

### 6.2 跨页面 Shared Partial

| Partial | 当前职责 | 使用注意 |
| --- | --- | --- |
| `_app_brand.html.erb` | 品牌图形 | 不承载页面标题 |
| `_auth_header.html.erb` | 账户页返回、标题、语言入口或右侧动作 | 所有入口按 local 传入，不自行猜测路径 |
| `_auth_intro.html.erb` | 账户页 eyebrow、标题、说明和可选品牌 | 允许控制是否显示品牌 |
| `_language_switcher.html.erb` | 基于原生 `<details>` 的语言菜单 | 当前是静态预览实现，不代表最终 locale 持久化方案 |
| `_bottom_navigation.html.erb` | 三项底部导航 | 有 path 时输出链接；无 path 时输出禁用按钮 |
| `_form_errors.html.erb` | Rails model 错误或明确传入的静态错误消息 | 当前账户页用静态消息预览效果；接入真实表单时传入 model object |
| `_result_card.html.erb` | 邮件、验证和空状态结果卡片 | 支持标题级别和 action block |

### 6.3 页面专用 Partial

| Partial | 当前职责 | 性质 |
| --- | --- | --- |
| `_record_card.html.erb` | 观察历史记录卡片与识别状态展示 | 页面域内复用 |
| `_bird_thumbnail.html.erb` | 历史记录中的示例 SVG 缩略图 | 仅代码现状；不是正式鸟类资产 |
| `_impression_bird.html.erb` | 编辑器和详情页的概念性抽象鸟 SVG | 仅代码现状；不是最终抽象鸟生成方案 |

优先抽取 Partial 的情况：

- 相同语义结构被两个以上页面使用；
- 结构有明确输入参数；
- 抽取后能减少重复且不会隐藏关键业务状态。

不应只因为几个元素外观相似就抽取复杂通用组件。Rails Partial 负责 HTML 结构复用，CSS class 负责视觉复用，Stimulus controller 负责行为复用，三者不必强行一一对应。

## 7. CSS 实现方式

### 7.1 当前组织

当前全部样式集中在 `app/assets/stylesheets/application.css`。文件大致按以下顺序组织：

1. B′ 视觉变量和全局规则；
2. 页面外壳、标题和排版；
3. 按钮、输入、表单和账户页；
4. 观察历史；
5. 轮廓选择；
6. 观察编辑器和抽象鸟预览；
7. Dialog；
8. 观察详情和识别操作；
9. 底部导航；
10. 窄屏、桌面容器和 reduced-motion 适配。

当前规模下维持单文件可以让视觉语言集中可查。只有当拆分能显著改善维护，并且不引入新的构建体系时，才应另行讨论样式拆分。

### 7.2 当前视觉变量

`:root` 中集中定义 B′“柔雾标本册”基础变量，包括：

- 表面与背景：`--mist`、`--paper`、`--paper-strong`；
- 文字与主色：`--pine`、`--body`、`--quiet`；
- 选择与辅助色：`--moss`、`--lake`、`--selection`、`--ginkgo`；
- 边线、危险色和阴影：`--line`、`--danger`、`--shadow`；
- 圆角：`--radius-card`、`--radius-control`；
- 间距：`--space-1` 至 `--space-6`；
- 字体：`--font-sans`、`--font-display`。

这些变量是当前实现的集中入口，但不是另行确立的完整设计系统。修改变量可能同时影响多个页面，修改前应对照高保真基线并检查至少一个账户页、历史页、编辑器和详情页。

### 7.3 响应式策略

当前页面采用“移动端单列应用表面 + 桌面端居中设备式容器”：

- HTML 和 body 最小宽度为 320px；
- `.app-page` 默认最大宽度 410px，并至少占满一个视口高度；
- 370px 以下压缩左右留白、卡片、网格和编辑器间距；
- 781px 以上将页面放入带圆角、边框和阴影的居中容器；
- 底部导航考虑 `safe-area-inset-bottom`；
- `prefers-reduced-motion: reduce` 下缩短动画和过渡。

新增页面时，先保证 320–410px 的主流程可用，再检查桌面容器内的滚动、固定区域和弹窗。不要以桌面宽屏为起点重新设计另一套布局。

### 7.4 命名与状态

当前 class 主要采用可读的组件式命名，例如：

- `.record-card`、`.record-card--confirmed`；
- `.status-pill`、`.status-pill--candidate`；
- `.candidate-row`、`.candidate-delete`；
- `.is-active`、`.is-selected`、`.is-set`。

建议继续遵循：

- 组件主体使用名词；
- 结构子元素使用 `__`；
- 稳定变体使用 `--`；
- 瞬时 UI 状态使用 `.is-*`；
- JavaScript 定位优先使用 `data-*` target，不依赖纯视觉 class。

最后一条能避免改样式名称时意外破坏交互。

## 8. Stimulus 与页面状态

### 8.1 为什么使用 Stimulus

Rails 服务端负责产生完整 HTML，Stimulus 只增强局部交互。当前不需要用前端框架重建路由、页面树或全局 store。

Stimulus 的核心连接方式：

```html
<section data-controller="example">
  <button data-action="example#choose"
          data-example-target="choice">
  </button>
</section>
```

- `data-controller` 连接 controller；
- `data-*-target` 声明 controller 要访问的元素；
- `data-action` 把浏览器事件连接到方法；
- `data-*-value` 将 Rails View 生成的路径或配置传给 JavaScript。

这些 data attributes 是 View 与 JavaScript 之间的接口。重命名任一端时必须同步修改，并用 System Test 验证。

### 8.2 当前 controller 分工

| Controller | 负责 | 不负责 |
| --- | --- | --- |
| `outline_selection_controller.js` | 两阶段轮廓选择、选中状态、继续按钮和前往编辑器 | 保存正式轮廓数据 |
| `observation_editor_controller.js` | 部位状态、颜色/特征/确定程度/位置选择、SVG 概念预览、保存条件、离开提醒 | 真实记录持久化和最终鸟图生成 |
| `identification_controller.js` | 候选与最终鸟名的局部状态、折叠、删除/修改暂存、离开保护、针对性撤销 Dialog | 正式识别数据、并发冲突和服务端校验 |

Turbo 和 Stimulus 已通过 importmap 加载。当前预览的主要互动仍由普通导航和 Stimulus 完成，尚未形成依赖服务器响应的 Turbo Frame 工作流。

### 8.3 状态设计原则

当前预览中可见两种状态层次：

1. **已保存状态**：模拟后端已经接受的数据；
2. **工作状态**：用户在当前页面尚未保存的编辑。

详情页的候选删除和最终名称修改会改变工作状态并出现保存入口；可逆且不会丢失数据的确认或撤销动作可以立即生效。未提交的非空鸟名输入与可能丢失的工作状态使用不同的离开提醒。

这些业务判断以正式需求和 UI 文档为准。Stimulus 只是当前静态预览中的演示载体；接入后端时，应由 Rails 参数、Model 校验和持久化结果重新建立真实状态，不能直接把浏览器内存当作数据源。

### 8.4 离开保护

当前使用两层保护：

- 应用内导航：拦截链接或返回操作，打开原生 `<dialog>`；
- 浏览器级离开：在确有未保存风险时注册 `beforeunload`。

维护时应遵循正式判断标准：是否存在数据丢失风险，以及操作是否可逆。不要把每次点击都包在确认弹窗里，也不要为了减少弹窗而静默丢弃非空输入或不可恢复的名称。

## 9. Rails I18n

当前支持：

- 简体中文：`config/locales/zh-CN.yml`；
- 日语：`config/locales/ja.yml`；
- 默认语言：日语。

翻译 key 目前按 `application` 和 `frontend_previews` 分组，再按 shared 或页面名称组织。新增或修改用户可见文案时：

1. 在 ERB 中使用 `t(...)`，不要直接写死正式 UI 文案；
2. 同时补齐 `zh-CN.yml` 与 `ja.yml`；
3. 保持两种语言的 key 结构一致；
4. 对插值、复数或动态鸟名检查转义和语序；
5. 运行双语言集成测试，确保页面没有 `translation missing`；
6. 实际查看长日语文案是否挤压按钮、标题和底部导航。

当前语言菜单使用带 query parameter 的本地预览链接。正式技术决策中的 locale 持久化方案仍应以 `docs/technical-decisions.md` 为准，不能把预览链接实现当作最终方案。

正式实现中，已保存的语言 Cookie 优先；没有 Cookie 时，所有 `zh*` 浏览器语言映射到 `zh-CN`，其他语言统一回退到 `ja`。英文显示已经延后，当前不创建英文翻译文件或页面。

## 10. 可访问性与移动端约定

当前实现已经使用或测试以下基础能力：

- `<html lang>` 与本地化页面 title；
- `:focus-visible` 焦点轮廓；
- 选择按钮的 `aria-pressed`；
- 页签的 `role="tab"` 与 `aria-selected`；
- 折叠候选区的 `aria-expanded` 和 `aria-controls`；
- 禁用按钮同时设置 `disabled` 与 `aria-disabled`；
- 状态消息使用 `role="status"` 和 `aria-live`；
- 表单错误使用 `role="alert"`；
- 装饰字符使用 `aria-hidden`，SVG 示例提供可读 label；
- 原生 `<dialog>` 用于模态确认；
- `.sr-only` 提供只对辅助技术可见的文本；
- reduced-motion 和移动端安全区适配。

新增交互时至少检查：

- 不用颜色作为唯一状态信号；
- 所有功能可由键盘到达和触发；
- 关闭 Dialog 后焦点回到合理位置；
- 展开、选中、禁用状态同时更新视觉与 ARIA；
- 触控区域不会因窄屏压缩得过小；
- 输入过程中不会因误触导航而无提示离开；
- 固定底栏不会遮挡最后一个表单控件或 Dialog 动作。

## 11. 测试与本地验证

### 11.1 测试分层

| 测试 | 主要覆盖 |
| --- | --- |
| `test/integration/frontend_previews_test.rb` | 所有预览能渲染、双语言、HTML 结构、链接、静态表单约束和初始状态 |
| `test/system/frontend_outline_preview_test.rb` | 两阶段选择、fallback 和跳转 |
| `test/system/frontend_editor_preview_test.rb` | 部位记录、保存条件、位置上限、离开保护和跳转 |
| `test/system/frontend_detail_preview_test.rb` | 确认/撤销、删除/保存、最终名称修改、候选保留/替换和离开保护 |
| `test/system/frontend_settings_preview_test.rb` | 语言切换、修改密码入口、历史/设置导航和退出登录 |
| `test/system/frontend_quality_preview_test.rb` | 320px、390px、桌面宽度、长日文、错误可访问性和短视口固定区域 |

System Test 使用 headless Chrome，默认窗口为 390×844。它能验证交互，但不能替代人工视觉比对和其他尺寸检查。

### 11.2 常用命令

静态前端测试可设置 `STATIC_FRONTEND_PREVIEW=1`，避免未建立业务数据库时触发测试 schema 维护：

该选项仅适用于隔离的静态预览测试，不用于证明数据库或后端接入通过。阶段 4 已在不启用该选项的正常本地环境运行全部现有测试；涉及业务或数据库时应使用正常 Schema 维护入口，执行环境与复现方式见 `backend-development-plan.md` 第 10、18 节。

```powershell
$env:STATIC_FRONTEND_PREVIEW = "1"
ruby bin/rails test test/integration/frontend_previews_test.rb
ruby bin/rails test:system
Remove-Item Env:STATIC_FRONTEND_PREVIEW
```

其他静态检查：

```powershell
ruby bin/rails zeitwerk:check
ruby bin/rubocop
bundle exec brakeman --no-pager
```

每个阶段的实际执行命令、测试数量、failures、errors、skips 和已知覆盖缺口，应记录在验收报告或 `docs/frontend-development-plan.md`，不要在本指南中保存容易过期的测试计数。

### 11.3 浏览器检查清单

在需要浏览器验收的阶段，至少检查：

- 简体中文与日语；
- 390×844 主移动端尺寸；
- 320–370px 窄屏；
- 781px 以上桌面容器；
- 页面首次进入、空状态、错误/禁用状态；
- 键盘焦点顺序、Dialog 打开关闭和焦点恢复；
- 长文案、滚动、底部导航与固定保存栏；
- 刷新后状态重置是否符合“静态预览”预期；
- 与高保真基线的整体布局、层级、表面、间距、圆角、边框和阴影差异。

## 12. 高保真基线与当前实现差异表

本表记录当前已知差异，不负责决定产品或 UI 方向。新的差异应先标注状态，再由对应角色判断是否进入正式文档。

| 区域 | 高保真基线或原始示例 | 当前 Rails 实现 | 状态与理由 |
| --- | --- | --- | --- |
| 编辑器初始值 | 高保真示例中部分部位已有颜色或花纹 | 首次进入为空，必须由用户主动记录 | 已确认适配：符合正式空白起始规则，示例数据不进入正式流程 |
| 次要颜色 | 高保真示例没有完整展开所有次要颜色状态 | 每个部位提供可选次要颜色，并允许取消 | 已确认适配：正式需求包含多个显著颜色 |
| 颜色、特征与位置列表 | 原型包含演示名称和有限示例 | 当前各提供有限静态选项，文案明确为示例 | 仅代码现状：正式可用选项和资产仍需后续确认或接入数据 |
| 抽象鸟图 | 高保真基线展示概念性鸟图 | ERB Partial 输出固定 SVG，并由选择结果改变填色和装饰 | 仅代码现状：用于验证布局和反馈，不是最终剪影或生成算法 |
| 历史缩略图 | 原型展示不同鸟类轮廓 | 当前使用几组手写 SVG variant | 仅代码现状：不是正式业务图片或鸟类资料 |
| 账户表单 | 高保真基线覆盖账户及辅助流程 | Rails 页面提供统一的 B′ 风格静态表单和跳转 | 已确认复用现有视觉组件；真实表单必须由服务器校验并遵守字段保留与错误分工规则 |
| 表单提交 | 原型点击可演示流程 | 当前表单标记 `data-static-preview="true"`，不设置真实 action | 仅代码现状：正式接入后使用真实 Route、Controller、Rails 表单和 CSRF 保护 |
| 语言切换 | 原型用于展示双语言页面 | 当前 `<details>` 菜单通过 `locale` query 切换 | 仅代码现状：正式实现以语言 Cookie 为准；无 Cookie 时 `zh*` 映射中文，其余回退日文 |
| 详情候选区 | 早期页面始终展示候选鸟名 | 已确认状态下默认折叠，待确认/候选中保持展开 | 已确认方向；阶段 5 已整体验收，但具体折叠文案和最终视觉仍为 Observed-only／暂定实现 |
| 识别保存逻辑 | 早期实现对多种操作统一出现保存按钮 | 可逆且无数据丢失的确认/撤销立即生效；删除和改名等有风险修改进入保存逻辑 | 已确认规则；当前 Dialog 排布和消息微文案只是已验收静态实现，不是最终 UI 规范 |
| 未提交鸟名 | 早期实现离开时不提示 | 非空候选名或其他最终鸟名输入会先触发未提交输入提醒 | 已确认规则；当前文案和按钮层级仍属暂定实现 |
| 撤销候选外最终名 | 早期撤销会直接清除名称 | 撤销时可保留为候选；候选已满时要求选择替换项，也可明确不保留 | 已确认规则；当前替换 Dialog 的具体视觉和微文案仍为 Observed-only |
| Turbo | 正式技术方向包含 Turbo | 已加载 Turbo，但预览交互主要是普通导航和 Stimulus | 仅代码现状：后端接入后再按真实响应决定 Frame/Stream 用法 |
| 桌面布局 | 高保真主要体现移动端应用表面 | 781px 以上显示居中的设备式页面容器 | 仅代码现状／暂定适配：保持 B′ 方向并便于桌面预览，不是独立设计系统决定 |
| 设置与修改密码 | 高保真基线包含设置和登录后修改密码页面 | 当前提供只读示例邮箱、双语 locale 链接、静态修改密码表单、退出入口和导航闭环 | 已确认页面结构下的静态实现；Cookie、会话和密码更新仍待后端接入 |
| 错误与边界状态 | 原型只覆盖部分状态 | 已有禁用、Dialog、空状态，并为登录凭证错误和注册密码不一致提供查询参数驱动的代表性静态效果 | 查询参数仅供预览；正式实现由服务器判断，字段错误、页面级通用提示和结果卡片按已确认分工使用，具体微文案与提交后焦点仍待验证 |

## 13. 新增或修改页面的推荐流程

### 13.1 开始前

1. 在 `requirements.md` 确认业务能力和规则；
2. 在 `mvp-scope.md` 确认当前版本是否包含；
3. 在 `ui-design.md` 确认页面、流程和状态；
4. 在 `technical-decisions.md` 确认技术边界；
5. 对照高保真基线，区分正式视觉与演示数据；
6. 检查 Git status、未暂存 diff 和暂存区 diff；
7. 提出小范围计划、拟修改文件和验证方式；
8. 未确认的视觉缺口交给 UI Designer，不在代码中自行定案。

### 13.2 实现时

1. 在 `config/routes.rb` 增加最小必要入口；
2. 在对应 Controller action 准备 View 所需数据；
3. 用 ERB 生成语义化 HTML；
4. 优先复用已有 Partial 和 CSS 变量；
5. 只有存在局部交互时才增加或扩展 Stimulus controller；
6. 用 `data-*-value` 传递 Rails 生成的 URL，不在 JavaScript 中拼接固定路径；
7. 同时补齐中日文翻译；
8. 对选中、展开、禁用、错误和保存状态补齐 ARIA；
9. 不把原型鸟名、颜色名、轮廓名或演示记录写成正式业务数据。

### 13.3 完成时

1. 运行相关 Integration Test 和 System Test；
2. 运行 `git diff --check`；
3. 按风险运行 Zeitwerk、RuboCop 和 Brakeman；
4. 在需要时检查移动端与桌面端浏览器；
5. 报告实际文件、命令、测试数量、failures、errors、skips 和覆盖缺口；
6. 报告与高保真基线的差异及原因；
7. 只有产生正式事实、规则、范围、设计或技术决定变化时，才输出变更交接单。

## 14. 当前已知缺口与延后内容

### 14.1 当前已知缺口

- 账户表单尚未接入真实校验、提交结果和服务器错误反馈；
- 当前 SVG 鸟图和缩略图只是概念性前端资产；
- 当前没有真实表单提交、认证、持久化、服务器校验或 Turbo 响应；
- 当前 14 个页面已完成 320px、390px、桌面宽度、长日文、键盘顺序和短视口的集中回归；真实移动设备、软键盘和 Safari、Firefox 等多浏览器验证仍未完成；
- 当前本地预览语言切换不持久化到 cookie。
- 本地 TLS 已在相同配置、获批准的非沙箱环境下完成连接和现有测试对照；沙箱上下文仍可能失败。证据见 `backend-development-plan.md`，不再把更换 TLS 方案当作接入前置条件，也不据此宣称生产身份验证或业务测试已完成。

### 14.2 已排除、未确认或不在本文档中决定

- 最终鸟类剪影资产和抽象鸟图生成细节：服务器生成 inline SVG 的高层路线已经确认；当前静态前端只提供概念图，最终剪影资产、部位映射配置和视觉生成细节仍未确认，不在本文档中决定；
- 真实鸟类图片上传：已确认不进入当前 MVP；
- 确认依据输入字段：已确认不进入当前 MVP，不得在领域模型、表单或数据库中预留；
- 后端 Model、Migration、认证和业务服务；
- 独立设计系统文档：已确认不创建，当前视觉变量、组件约定和维护说明继续集中在本指南与正式 UI 文档中；
- 新前端框架或独立构建体系。

“不进入当前 MVP”不等于永久否决；是否进入后续版本仍以正式产品文档和用户确认结果为准。

## 15. 本文档的维护规则

以下变化发生时，应核对并按需更新本文档：

- Rails 前端目录或渲染链路变化；
- 新增共享 Partial、Stimulus controller 或测试层；
- CSS 组织、响应式策略或可访问性约定变化；
- locale 组织或前端翻译流程变化；
- 高保真基线与正式实现之间出现新的有意差异；
- 静态预览接入真实后端，导致状态和数据流发生变化；
- 已知前端缺口完成、取消或改变处理方式。

不应在本文档中维护：

- 产品范围和业务规则原文；
- 阶段完成百分比和最新测试计数；
- 尚未确认的想法清单；
- 仅为一次实现过程服务的临时笔记；
- 可由代码直接准确说明的大段 API 或 class 清单。

更新本文档时，应同时检查它是否仍与正式文档一致，并由 Project Maintainer 判断文档导航、状态说明和其他正式文档是否需要同步。
