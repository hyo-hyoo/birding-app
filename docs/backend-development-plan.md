# 观鸟 Web App｜后端开发计划与进度

> 文档性质：Rails 后端开发、纵向切片实施与验收跟踪文档  
> 当前分支：`codex/backend-development`  
> 建立日期：2026-08-17  
> 当前阶段：阶段 6 待用户验收；M1、M2-A、M2-B 与 M2-C 已实现并通过机械验证，“注册→验证→登录→空历史→退出”闭环待用户确认
> 当前目标：完成数据库设计基线，并按纵向切片接入真实业务，最终形成可在本地验收的 MVP 闭环

## 1. 文档职责

本文档只负责：

- 后端开发阶段、依赖关系与实施顺序；
- 每个阶段的范围、交付物、阻塞和完成标准；
- Migration 与纵向切片的分批实施计划；
- Rails 后端学习重点；
- 实际修改、测试、浏览器验证和用户验收证据；
- 当前进度与下一步。

本文档不拥有以下事实：

- 产品能力与业务规则，以 [requirements.md](requirements.md) 为准；
- MVP 范围与完成标准，以 [mvp-scope.md](mvp-scope.md) 为准；
- 页面、流程、状态与 UI 决定，以 [ui-design.md](ui-design.md) 为准；
- 架构与技术选择，以 [technical-decisions.md](technical-decisions.md) 为准；
- 当前项目阶段和短期阻塞，以 [current-status.md](current-status.md) 为准；
- Rails 前端组织与维护方式，以 [frontend-implementation-guide.md](frontend-implementation-guide.md) 为准；
- ER 图、表、字段、外键、索引和约束的详细设计，以 [database-design.md](database-design.md) 为准；
- 未确认想法，以 [idea-dump.md](idea-dump.md) 为准，且不得自动作为开发任务。

当本计划与上游正式文档冲突时，不得用计划反向覆盖上游决定。应先停止受影响的实施，区分内容是已确认、暂定、未确认、延后、否决、AI 建议或 observed-only，再交由相应讨论和文档维护流程处理。

## 2. 开发目标与边界

### 2.1 目标

- 从已验收的静态 Rails 前端出发，接入真实 Route、Controller、Model、数据库、Session、Mailer、Job 和服务器校验；
- 先完成整个 MVP 的领域模型与物理数据库设计基线，再按纵向切片逐步创建 Migration；
- 每个切片都形成可运行、可测试、可解释和可由用户验收的端到端流程；
- 把 Ruby on Rails 后端学习作为实施主线，能够说明请求、业务规则、持久化、授权与响应之间的数据流；
- 在本地完成 MVP 闭环后，再进入部署准备。

### 2.2 当前不包含

- 生产托管平台、域名、HTTPS、生产 MySQL、真实邮件服务、监控和生产备份；
- React、Vue、独立 SPA、独立前端仓库或纯 JSON API 后端；
- Devise、Pundit、CanCanCan、Java 风格 Repository／DAO 层；
- 未经确认的鸟类配置、UI 细节或产品能力；
- 自动推荐鸟种、鸟类数据库、图片上传、语音解析和其他已排除的 MVP 外能力；
- 新建 Backend Architect、Database Designer 等专门 Agent 或 Skill；
- 为 Harness Engineering 预先建设完整复杂的自动化治理体系。机械化架构约束、文档一致性检查或其他 Sensors 只在后续真实开发出现重复失误或质量问题时再评估，不预先作为开发任务。

### 2.3 决策权限与升级边界

从阶段 2 开始，后端开发默认采用“Agent 自主执行、关键决定升级、机械验证、用户验收业务行为和核心 Rails 链路”的方式。

- 开发 Agent 根据正式需求、既有技术决定、Rails 常规实践和项目约束，自主完成低成本、可逆的领域建模、文件组织、约束设计、测试拆分和其他常规工程决定；不要求用户逐项审批。
- 决定涉及产品行为或 MVP 范围、已确认主要技术路线、安全／隐私／认证／不可恢复数据风险、主要依赖或基础设施、高迁移成本，或者正式文档存在无法自行解决的冲突时，必须停止受影响工作并升级给用户。
- 每次升级只提出当前真正阻塞的少量问题，通常不超过 1～3 个，并说明推荐方案、风险和阻塞原因，不默认生成大量 A／B／C 选项。
- 能由 Minitest、System Test、数据库约束、RuboCop、Brakeman 或其他可重复检查验证的正确性，优先使用验证证据判断，不交给用户人工审批实现细节。
- 用户主要确认重要产品和风险边界、验收用户可见业务行为，并在重要纵向节点理解核心 Rails 请求链路。
- 未阻塞当前阶段或切片的未来技术问题继续显式保留并按需处理，不要求在正式后端开发前一次性解决完毕。

## 3. 信息与进度状态

### 3.1 决定状态

| 状态 | 含义 |
| --- | --- |
| `confirmed` | 用户已明确确认，或当前正式文档已经记录为正式决定 |
| `provisional` | 当前暂定采用，实施或验收后仍可能调整 |
| `open-question` | 尚未得到用户决定，不能用框架默认值或 AI 建议代替 |
| `deferred` | 当前阶段明确不处理，后续可重新评估 |
| `rejected` | 已明确否决，不得在没有新决定时重新引入 |
| `observed-only` | 只存在于代码、原型或示例，不能单独证明正式决定 |
| `AI-suggested` | 仅由 AI 提出，尚未得到用户确认 |

### 3.2 阶段进度

| 状态 | 含义 |
| --- | --- |
| `未开始` | 尚未进入该阶段 |
| `进行中` | 已开始实施或讨论 |
| `阻塞` | 存在必须先解决的依赖 |
| `待验收` | 实施和验证完成，等待用户确认 |
| `已完成` | 阶段完成标准和必要机械验证已经满足；用户可见业务阶段还需用户验收 |

决定状态与阶段进度不得混用。例如，一个阶段可以处于“进行中”，其中仍包含 `open-question`。

## 4. 当前开发基线

初始基线（2026-08-17；不是本轮复测结论）：

- Rails 项目骨架、开发库、测试库和 `/up` 健康检查已经完成基础验证；
- 静态 Rails 前端的 14／14 个计划页面或流程状态，以及前端阶段 1～7，已经通过用户验收；
- 静态前端已有 Rails Views、Partial、CSS、Stimulus、I18n、代表性错误效果和响应式回归；
- 当前没有正式 User、Session、Observation 或其他业务 Model、Migration、认证和持久化流程；
- 静态预览中的查询参数、示例数据和浏览器内存状态不得直接成为正式业务数据源；
- 第一个纵向切片已经确认为“可登录的空观察历史”；
- 密码、邮箱验证链接、验证邮件重发限流、登录 Session 和浏览器语言归类规则已经确认；
- 完整数据库相关测试当前被 Windows `mysql2` 与 MySQL 8.4.10 的 TLS 协商问题阻塞；
- 当前分支为 `codex/backend-development`。

静态前端的详细实现状态见 [frontend-development-plan.md](frontend-development-plan.md) 和 [frontend-implementation-guide.md](frontend-implementation-guide.md)。

## 5. 总体依赖路线

```text
阶段 1：后端设计快速收口
  架构边界 / 业务模块 / 请求数据流 / 授权边界
                    ↓
阶段 2：MVP 领域模型与 ER 图
  实体 / 关系 / 基数 / 生命周期
                    ↓
阶段 3：物理数据库设计基线
  表 / 字段 / 类型 / NULL / FK / Index / 约束
                    ↓
阶段 5：Migration 实施计划
  设计整体，按纵向切片分批创建
                    ↓
阶段 6：纵向切片 1
  注册 → 验证 → 登录 → 空历史 → 退出
                    ↓
阶段 7～9：后续业务切片（顺序暂定）
                    ↓
阶段 10：全 MVP 回归与本地验收
```

阶段 4「MySQL TLS 解决与验证」可以与阶段 1～3 的讨论和设计并行，但必须在执行任何业务 Migration、数据库业务测试或真实持久化接入前完成。

## 6. 阶段总览

| 阶段 | 交付内容 | 主要依赖 | 当前状态 | 决定状态 |
| --- | --- | --- | --- | --- |
| 1 | 后端设计快速收口 | 正式需求、MVP、UI、技术决定 | 已完成 | `confirmed` |
| 2 | MVP 领域模型与 ER 图 | 阶段 1 | 已完成 | `confirmed` 范围，工程设计已核查 |
| 3 | 物理数据库设计基线 | 阶段 2 | 已完成 | `confirmed` 范围，工程设计已核查 |
| 4 | MySQL TLS 解决与验证 | 相同配置本地运行对照与测试 | 已完成（本地） | 实际验证，不改变TLS策略 |
| 5 | Migration 实施计划 | 阶段 3、阶段 4 | 已完成 | `confirmed` 范围，工程计划已核查 |
| 6 | 纵向切片 1：可登录的空观察历史 | 阶段 5 | 待验收：M1、M2-A、M2-B、M2-C 实现与机械验证通过 | `confirmed` |
| 7 | Observation 核心闭环 | 阶段 6 | 未开始 | `provisional` |
| 8 | SVG 与摘要渐进增强 | 阶段 7、正式配置准备 | 未开始 | `provisional` |
| 9 | 鸟种确认、账户辅助与设置 | 前序切片 | 未开始 | `provisional` |
| 10 | 全 MVP 回归与本地验收 | 全部 MVP 切片 | 未开始 | `provisional` |

阶段 2～5 原暂定作为一次较短的后端设计与基础设施冲刺，现已按用户授权完成交付；各阶段分别记录设计、TLS 调查、Migration 映射及验证证据。该完成状态不表示用户逐字段审批了工程设计，也不表示已经实施业务功能；后续继续按 2.3 节处理决策升级。

阶段 6 以后继续使用同一决策升级机制，并在重要纵向节点增加学习型请求链路 walkthrough。阶段 7～10 的当前依赖顺序仍为 `provisional`；开发 Agent 可以按正式依赖继续细化，但不能借此改变产品范围或把未决产品规则自行确认。

## 7. 阶段 1：后端设计快速收口

**状态：`已完成`**
**决定状态：`confirmed`**

### 7.1 目标

- 明确 Rails 模块化单体中的业务模块和职责边界；
- 明确浏览器请求进入 Route、Controller、Model、Mailer／Job 和 View 的主要数据流；
- 明确账户、观察记录和识别操作的授权边界；
- 区分持久化数据、派生数据、版本控制配置和浏览器状态；
- 识别会影响 ER 图或物理数据库设计的未确认问题。

### 7.2 完成结果

已完成并由用户确认：

- Account、Login Session、EmailVerification、Observation、PartImpression 和 BirdIdentification 六个业务模块的职责、非职责与协作边界；
- 行动位置与行为、版本控制配置、SVG 与文字摘要、Locale、PasswordManagement、Mailer 和 Job 的辅助职责边界；
- 模块名称只用于表达业务职责，不要求创建同名 Ruby 类、Namespace、Service、Model、Controller 或目录；
- 重复注册、邮箱发送失败恢复、两步邮箱验证、未验证登录、登录返回路径、Session 恢复与退出、观察保存与预览、鸟种识别命令等主要请求流；
- 当前用户授权边界、服务器信任边界和 CSRF、敏感日志、内部返回路径等安全原则；
- 持久化、派生、版本控制配置、浏览器临时状态和敏感运行时数据分类；
- 进入 ER 图阶段前的业务依赖、并发、令牌、限流、清理、物理结构与 MySQL TLS 未决问题；
- 本阶段未编写业务代码、未创建 Migration，也未绘制正式 ER 图。

### 7.3 交付物

- 模块边界清单；
- 主要用户流程的数据流；
- 授权边界和信任边界；
- 持久化／派生／配置／浏览器状态分类；
- 进入 ER 图阶段前的未决问题列表。

### 7.4 不包含

- 不画最终 ER 图；
- 不决定具体表名和字段类型；
- 不创建 Migration；
- 不修改业务代码。

### 7.5 完成标准

- 各业务模块有清晰职责且不存在明显重复所有权；
- 主要端到端流程的数据流可以被用户理解和复述；
- 数据分类和授权边界得到确认；
- 所有影响下一阶段的未决问题被显式列出；
- 用户确认进入阶段 2。

## 8. 阶段 2：MVP 领域模型与 ER 图

**状态：`已完成`**
**决定状态：`confirmed`**

### 8.1 目标

- 以业务概念描述整个 MVP 的实体、关系、基数和生命周期；
- 先确认“业务上存在什么”，不提前受具体 Migration 写法影响；
- 明确账户令牌、限流数据和观察识别数据是否需要独立实体。

### 8.2 已确认概念基线

```text
User
├─ has_many Session
└─ has_many Observation
   ├─ has_many PartImpression
   ├─ has_many BirdCandidate
   └─ has_many ActivityLocationSelection
```

该关系只是正式技术文档中的概念级起点，不是最终 ER 图或数据库 Schema。

### 8.3 交付物

- 完整 MVP 概念实体清单；
- ER 图；
- 关系与基数说明；
- 聚合边界和对象生命周期；
- 派生状态与持久化状态的分界；
- 未确认实体和备选建模方式。

### 8.4 完成标准

- 全部已确认 MVP 能力均能映射到领域对象或明确的非持久化职责；
- 账户、观察、部位、候选、行动位置之间的关系得到确认；
- 验证令牌、重置令牌和限流数据的建模方向得到明确记录，触发升级条件的阻塞已交给用户处理；
- ER 图经过一致性检查并记录依据后进入阶段 3，不要求用户逐个审批常规实体和关系。

详细设计在 [database-design.md](database-design.md) 中维护。

### 8.5 本轮交付与核查

- 数据库设计第7～8节给出10个实体、8条所有权关系、基数、聚合边界与生命周期；第8.1节逐项覆盖requirements的6.1～6.13。
- 最终鸟名位于Observation，不以模块名另建BirdIdentification表；令牌用途分表，限流主体不依赖User存在。
- 明确Observation与识别两个修改范围，所有权FK不替代Current.user授权。
- 用户接受邮件入队语义、安全数据最少保留与文本上限；其余常规结构为开发Agent设计，不冒充用户逐字段决定。
- ER图为仓库内Mermaid源，已核对节点、关系及基数说明；不声称完成图像渲染验收。

## 9. 阶段 3：物理数据库设计基线

**状态：`已完成`**
**决定状态：`confirmed`**

### 9.1 目标

- 将已确认 ER 模型转换为 MySQL 8.4 的关系结构；
- 明确表、字段、类型、长度、默认值、NULL、外键、索引和约束；
- 明确 Rails Validation 与数据库约束的职责分工；
- 识别计数上限、并发写入、令牌安全和删除策略等风险。

### 9.2 设计范围

- 主键和外键；
- 邮箱规范化与唯一性；
- 密码摘要与敏感令牌摘要；
- Session 到期与失效；
- 验证邮件发送与限流记录；
- Observation 首次保存时间和后续更新时间；
- 每个 Observation 的部位唯一性；
- 候选鸟名最多三个；
- 行动位置最多两个；
- 稳定配置键；
- 删除行为、事务和并发保护；
- 核心查询所需索引。

### 9.3 完成标准

- 每张表都有明确职责和数据字典；
- 每个字段的存在理由、类型、可空性和长度可解释；
- 外键、唯一性、索引、删除策略和并发风险得到说明；
- 没有把 SVG、文字摘要、识别状态或 locale 偏好错误持久化；
- 未确认产品规则没有被写成正式字段或约束；
- 物理设计通过一致性、约束、索引和风险检查，触发升级条件的问题已经处理后进入阶段 5。

### 9.4 本轮交付与验证边界

- 数据库设计第9～10节：10张完整MVP表的职责、字段、类型、长度、NULL、默认值、FK、UNIQUE、CHECK与索引。
- 第12～15节：Rails与DB分工、查询映射、双版本行锁、令牌入队／消费、限流当前读、清理与隐私。
- MySQL只读SQL核查26项：两库分别5项精确比较＋8项令牌状态布尔表达式；0失败，无DDL。避免把CHECK中的UNKNOWN误认为false。
- 本阶段未建表，因此尚不能证明真实FK／CHECK拒绝行为、Migration回滚或schema.rb往返；这些明确映射到对应实施批次，而非从普通静态前端测试推断已覆盖。

## 10. 阶段 4：MySQL TLS 解决与验证

**状态：`已完成（本地连接与现有完整测试）`**
**决定状态：保留现有配置；未发生TLS安全策略或客户端依赖变更**

### 10.1 当前问题

原问题：沙箱下连接出现2026/HY000、SEC_E_NO_CREDENTIALS。2026-08-31对照显示，相同配置只把执行上下文改为获批准的非沙箱本地环境即可成功；直接阻塞定位在Windows Schannel沙箱执行上下文，尚未证明内部具体缺少哪项权限。不是已证实的数据库密码或CA故障。

### 10.2 实际处理

- 保留Ruby4.0.6、Rails8.1.3.1、mysql2 0.5.7及MariaDB Connector/C 3.4.9；实际DLL为`D:\Ruby40-x64\msys64\ucrt64\bin\libmariadb.dll`。
- 只在获工具批准的非沙箱上下文验证连接／测试，不修改database.yml、证书、密码、服务或客户端库。
- 原先“关闭验证”与“改Oracle客户端”两项均未选用，不写成用户已否决，也不再把二选一作为当前连接前置条件。
- Rails对development与test均两次成功连接，端口3307、MySQL8.4.10、目标库正确；TLS1.2、cipher `ECDHE-RSA-AES256-GCM-SHA384`。
- Ssl_cipher证明加密，不证明已验证CA／主机身份。当前服务器require_secure_transport=0是观察事实，未修改；生产TLS策略仍延后。
- 两库前后均仅有ar_internal_metadata、schema_migrations，迁移数0；没有业务表。MySQL和MySQL84服务均Running；未连接、停止或修改旧MySQL5.7实例及数据。

### 10.3 完成标准

- 涉及TLS或依赖变更时先由用户批准；本轮无此变更，非沙箱连接／测试均获工具审批；
- 开发库和测试库均能由 Rails 稳定连接；
- 测试 Schema 维护和完整 Rails 测试不再因 TLS 中止；
- 不影响现有 MySQL 5.7 服务和数据；
- 实际命令、环境差异和验证结果得到报告；
- 相关正式技术决定由后续文档维护流程同步。

### 10.4 实测记录（2026-08-31）

| 命令／检查 | 结果 | 环境与范围 |
| --- | --- | --- |
| guarded mysql2只读连接 | 沙箱2次失败；非沙箱4次成功 | 独立调查的驱动层对照，不计为Minitest |
| guarded Rails连接／SQL核查 | 两库各2次Rails连接成功；26项SELECT核查通过 | 第一次连接确认基线，第二次在测试后复核；无DDL |
| `bundle exec ruby bin/rails test` | 15 tests、441 assertions、0 failures/errors/skips；seed46369 | 非沙箱，无STATIC_FRONTEND_PREVIEW；正常Schema维护入口 |
| `bundle exec ruby bin/rails test:system` | 13 tests、312 assertions、0 failures/errors/skips；seed60572 | 非沙箱，本地headless Chrome |
| `bundle exec ruby bin/rails zeitwerk:check` | All is good，exit0 | 正常应用加载 |
| `bundle exec rubocop --format simple` | 33文件，0违规，exit0 | 沙箱缓存目录不可写，仍完成扫描 |
| `bundle exec rubocop --cache false --format simple` | 33文件，0违规，exit0 | 无缓存复测消除环境噪声 |
| `bundle exec brakeman --no-pager` | 79检查，0错误、0警告，exit0 | Windows提示fork不支持，但扫描完成 |

合计现有自动测试28个、753个断言，无失败、错误或跳过。不新增业务测试，因为本轮没有实现业务行为；这些测试验证静态前端／健康检查和正常DB入口，不证明认证、授权、Mailers、限流或新Schema已实现。

运行数据库命令前必须检查实际Rails配置，限定`127.0.0.1:3307`、非root `birding_app`、开发／测试两个指定库；遇到DATABASE_URL或其他目标覆盖时停止。测试前确认无业务表和Migration；不得用STATIC_FRONTEND_PREVIEW绕过。无需为了复现修改全局运行配置。

## 11. 阶段 5：Migration 实施计划

**状态：`已完成`**
**决定状态：`confirmed`**

### 11.1 原则

- 先设计整个 MVP 数据模型，再按纵向切片创建表；
- 不在第一个切片中提前创建尚未使用的观察业务表；
- 每个 Migration 必须对应当前切片的真实需求；
- 已经执行或合并的 Migration 不为“整理历史”而直接改写；
- Schema 变化通过新的 Migration 演进；
- Migration、Model Validation、数据库约束和测试一起设计。

### 11.2 分批映射

| 切片 | 预计涉及的数据范围 | 状态 |
| --- | --- | --- |
| M1／纵向切片1 | users → sessions | 已实施并验证；正式页面在M2串联 |
| M2／纵向切片1 | email_verification_tokens；rate_limit_keys → send_attempts | M2-A～C 已实施并验证；未新增表，完整闭环待用户验收 |
| M3／Observation核心 | observations → part_impressions、activity_location_selections | 必须整体具备最低保存条件，不能只保存轮廓 |
| M4／鸟种识别 | Observation新增最终名／识别版本 → bird_candidates | M3之后，不能覆盖内容版本 |
| M5／密码辅助 | password_reset_tokens | 结构依赖M1，邮件流程复用M2；不进入首切片 |

表的精确名称、FK、测试映射及回滚风险见database-design第16节。M4与M5没有彼此FK依赖；业务交付顺序可后续细化。SVG／摘要增强不需要新增业务表。

### 11.3 完成标准

- 每个计划 Migration 都有对应切片、业务规则和测试范围；
- 迁移顺序、回滚风险、外键依赖和数据生命周期得到说明；
- 第一个 Migration 小任务范围可以从正式设计追溯，且不存在尚未处理的产品、安全或高迁移成本升级项；
- 不在本阶段直接执行 Migration。

### 11.4 阶段6首个小任务

范围：M1 User／Session及认证生成器最小接入，不创建观察表、不实现密码重置。先列出生成器将影响的文件，读取前端实施约定后再处理Views／I18n；审查生成器默认密码、会话、限流和重置输出，不让默认行为覆盖正式要求。

配套测试：规范化邮箱唯一性及SQL重复拒绝、密码8～20 ASCII规则、未验证不可登录、独立Session与固定30天、退出当前不影响其他会话、Cookie无效／过期；使用真实MySQL测试库并报告全部计数。尚无完整邮箱验证时不将M1单独包装成首个用户闭环已完成。

M2随后实现注册／验证／重发／Mailer与Job及空历史权限，完成阶段6验收；全程保留当前已验收静态页面为视觉参考，不使用查询参数决定业务结果。

## 12. 阶段 6：纵向切片 1——可登录的空观察历史

**状态：`待验收`（M1、M2-A、M2-B、M2-C 实现与机械验证通过；等待用户验收完整闭环）**
**决定状态：`confirmed`**

### 12.1 用户验收流程

1. 根据语言 Cookie 或浏览器语言进入中文或日文注册页；
2. 使用邮箱、密码和确认密码注册；
3. 在本地浏览器中打开 15 分钟有效的验证邮件链接；
4. 必要时通过两个共用后端流程和限流统计的入口重新发送验证邮件；
5. 验证成功后返回登录页，不自动登录；
6. 用户手动登录并进入自己的空观察历史；
7. 用户退出后，当前 Session 立即失效，受保护页面不可继续访问。

### 12.2 建议的小步顺序

1. User、Session 与认证生成器基线；
2. 注册与服务器密码规则；
3. 邮箱验证令牌、Mailer、Job 和两个重发入口；
4. 重发限流与不泄露账户状态的结果反馈；
5. 登录、当前 Session、30 天到期和退出；
6. locale Cookie、浏览器语言判断和邮件 locale；
7. 受保护的空观察历史；
8. 端到端回归与用户验收。

每一项都应作为独立的小任务，在开始前说明数据流、预计文件和测试方案。

### 12.3 不包含

- 忘记密码；
- 登录后修改密码；
- 设置页真实业务；
- Observation 和其他观察记录业务表；
- SVG、文字摘要、Turbo Frame 预览和 Stimulus 自动更新；
- 生产邮件和正式部署。

### 12.4 完成标准

- 正向流程可在真实 Rails 页面和本地数据库中完成；
- 登录、验证、限流和授权的关键异常路径有自动化测试；
- 真实后端复用已验收的 Rails 前端结构，不保留查询参数控制业务结果；
- 测试报告包含命令、tests、assertions、failures、errors、skips 和覆盖缺口；
- `bin/rails test`、相关 System Test、RuboCop、Brakeman 和实际浏览器流程通过；
- 用户完成验收并确认进入下一切片。

### 12.5 M1 实施与验证记录（2026-08-31）

**状态：本批工程基础已实现并验证；阶段6仍进行中。** 用户授权“下一步”，按11.4实施；没有扩大MVP或新增产品决定。认证／完整性工作按HIGH处理，关键验证通过后的重复检查和进度记录按LOW处理；未切换当前会话模型、未创建subagent。

#### 实际改动与范围

- `Gemfile`／`Gemfile.lock`：启用既定`has_secure_password`所需bcrypt 3.1.22；未升级其他依赖。
- `db/migrate/20260831000001_create_users.rb`、`20260831000002_create_sessions.rb`与生成的`db/schema.rb`：按既有设计建User、Session，带精确列比较、NOT NULL、唯一索引、CHECK和限制性FK；没有观察或令牌表。
- `app/models/user.rb`：统一邮箱规范化、格式／长度／唯一校验、密码8～20 ASCII字母数字及确认校验、验证状态。显式关闭生成器默认无状态password_reset_token，独立用途的密码重置留M5。
- `app/models/session.rb`：锁外authenticate及同实例digest快照，锁内当前读、digest／验证资格复核后建立Session；服务器同一时刻生成创建时间与固定30天期限，普通更新不可更改所有者、创建时间或期限。
- `app/models/current.rb`、`app/controllers/concerns/authentication.rb`：请求身份、加密Cookie定位、每请求数据库存在／到期检查、当前Session退出删除；不保存IP／User-Agent。Cookie为HttpOnly／SameSite=Lax，代码仅生产环境启用Secure，本地HTTP不宣称安全传输。
- 已只读审查本机Rails认证生成器并运行`generate authentication --pretend`，按其结构选取上述最小部分；未生成密码重置Controller／Mailer／Views，未改变正式路由、ApplicationController或现有静态前端。Authentication在M2挂入正式请求链路。
- 新增Model／约束／并发／认证请求测试及共用测试数据辅助。请求测试使用未挂载到应用的独立测试Controller和路由，只验证真实Cookie中间件、数据库和CSRF；其中JSON、HTTP状态和`/protected`等路径不是产品接口决定。
- `test/test_helper.rb`：在Rails准备测试表前检查已解析的本地测试库目标；共享MySQL库的普通测试默认单worker，避免全局时间／请求状态和非事务测试数据互扰。真实并发仍由独立连接与线程栅栏执行，不以串行模型测试替代。
- `script/verify_m1_schema.rb`：带显式`--execute`、库地址／版本、空表和M1版本守卫的往返验证脚本；只重建空测试库的两张业务表，不drop整个库、不处理开发数据。进入后续批次后会拒绝执行，不能当作通用清库命令。

#### 数据库执行与结构往返

执行前两库仅有Rails元数据表、无业务数据。在原连接配置下，按实际配置守卫限定`127.0.0.1:3307`、账号`birding_app`及开发／测试两库，调用Rails MigrationContext和Schema dumper执行M1。两库均完成版本`20260831000001`、`20260831000002`。

空测试库实际执行down（Session先于User）、up及schema.rb load；比较列类型、NULL／默认、时间精度、精确collation、存储引擎、索引、CHECK、FK及迁移版本，并在load后重新运行实际非法写入测试。

**已验证的框架表现，不是新产品决定**：Rails 8.1.3.1 MySQL适配器在dump时省略默认RESTRICT；重建后MySQL元数据显示NO ACTION。当前InnoDB下两者均立即拒绝受引用父记录的删除／键更新，不是级联或延迟校验。[MySQL官方说明](https://dev.mysql.com/doc/refman/8.4/en/create-table-foreign-keys.html)。Migration仍显式写RESTRICT；往返比较只在确认InnoDB后统一这两种等价标记，真实拒绝行为测试保留，未更换schema.rb、修改适配器或关闭外键检查。

最终两库各有`users`、`sessions`及2张Rails元数据表；User／Session均0条。TLS仍为TLS1.2／ECDHE-RSA-AES256-GCM-SHA384。首轮失败并发测试残留的1个专用测试账户和1条Session已精确清除；没有删除开发数据、修改MySQL5.7或提交Git。

#### 命令与结果

数据库／浏览器命令在获批准的正常本地执行上下文运行，未使用STATIC_FRONTEND_PREVIEW绕过Schema维护；环境差异沿用10.4，不修改TLS策略。

| 命令／检查 | 最终结果 |
| --- | --- |
| `bundle install` | bcrypt 3.1.22安装／原生扩展通过；仅增加此依赖及校验和 |
| `bundle exec ruby bin/rails test` | seed64930：48 tests、666 assertions，0 failures／errors／skips；其中33个为本批新增测试 |
| `bundle exec ruby bin/rails test:system` | seed1831：13 tests、312 assertions，0 failures／errors／skips；既有静态前端回归 |
| `bundle exec ruby bin/rails test test/models/authentication_concurrency_test.rb --seed N` | N=101～105各5 tests／19 assertions，全部0 failures／errors／skips；这是重复验证，不算25个新增测试 |
| `bundle exec ruby script/verify_m1_schema.rb --execute` | 空测试库down/up和schema.rb往返通过；属结构验证，不计入Minitest数量 |
| `bundle exec ruby bin/rails zeitwerk:check` | All is good，exit0 |
| `bundle exec rubocop --cache false --format simple` | 46文件、0违规，exit0 |
| `bundle exec brakeman --no-pager` | 79检查、0错误、0安全警告，exit0；Windows仍提示不支持fork但扫描完成 |
| `git diff --check` | 通过；未执行add／commit／push |

完整普通＋System Test合计61个、978个断言，0失败、错误或跳过。

首轮新增测试为31个／180断言、3失败／5错误／0跳过。已修正测试中的微秒单位、Rack Cookie删除判定／浏览器重置，以及撤销模拟中的CollectionProxy删除语义：有RESTRICT关联时，默认`association.delete_all`可能尝试置空FK；撤销须显式DELETE。随后31个／216断言全通过，并补充真实FOR UPDATE顺序和未过期加密Cookie不能覆盖数据库到期状态，最终得到上表结果。首轮结构脚本也如实发现RESTRICT／NO ACTION元数据差异，核对框架源码和InnoDB语义后按等价行为验证；没有删除或跳过失败用例。

#### 学习链路与剩余边界

本批测试链路：测试请求 → 测试Route／Controller → Authentication → Session.authenticate → User规范化查询与锁外密码校验 → 事务内User锁／当前状态复核 → Session INSERT → 加密Cookie。之后每个请求由Cookie定位数据库Session并检查期限，再恢复Current.user；退出只DELETE当前Session。正式Route／Controller／View或Redirect的用户链路留M2演示，不能把测试响应当作已完成的登录页面。

已覆盖两种密码写入／登录提交顺序、验证资格重读、认证→FOR UPDATE→INSERT顺序、两连接唯一邮箱竞争、真实SQL约束拒绝、Cookie伪造／重放／过期、不续期、独立会话退出、CSRF拒绝和请求身份隔离。密码更新只在测试中模拟已批准原子协议，不代表密码重置功能完成。

尚未覆盖／实施：注册与邮箱验证、M2故障矩阵、真实受保护页面／安全返回路径、locale串联、正式账户System Test、日志与邮件隐私全链路、过期Session次日维护命令、完整密码辅助、生产Secure／TLS部署验证。Session到期已即时不可用，不依赖未来清理命令；次日维护须在阶段6结束前落实。现有静态页面保持原状，不提供绕过验证的临时账户或登录入口。本批没有新的阻塞性产品问题；后续正式页面交付仍需用户验收。

### 12.6 M2-A 实施与验证记录（2026-08-31）

**状态：本批令牌与数据库限流基础已实现并验证；不是整个 M2 或阶段6完成。** 用户授权继续，按既有数据库设计实施，未新增产品决定、依赖或基础设施。认证、完整性及并发按 HIGH 处理；通过后的重复验证和执行记录按 LOW 处理，未切换会话模型、未创建 subagent。

M2-A／B／C 是本次开发的工程拆分，不改变既定 Migration 批次或验收范围：A 为三表及核心协议，B 为注册、令牌签发／切换及邮件 Job，C 为正式页面、locale、完整登录／空历史和维护清理。

#### 实际改动与范围

- `db/migrate/20260831000003_create_email_verification_tokens.rb`、`20260831000004_create_verification_rate_limit_keys.rb`、`20260831000005_create_verification_send_attempts.rb` 与生成的 `db/schema.rb`：按既有设计增加三表；保留精确比较、摘要格式、状态 CHECK、限制性 FK、唯一 active token、限流键唯一性与查询索引。字段使用 `rate_limit_passed`，不代表真实发送了邮件。未改 M1 Migration、ER 关系或完整 MVP 的10表设计。
- `app/models/email_verification_token.rb`：生成256位随机 secret、用途隔离摘要；只读检查与 POST 确认使用 User → token 锁顺序，锁后重读状态和时间。确认在同一事务验证 User 并消费 token，不自动创建 Session；过期、已消费、已替代、已清理及资格变化均拒绝再次确认。返回脱敏邮箱，不返回原始令牌。
- `app/models/user.rb`：增加令牌关联及限制性删除；没有调整账户或密码规则。
- `app/models/verification_rate_limit_key.rb`、`verification_send_attempt.rb`、`verification_rate_limiter.rb`：邮箱与 IP 用作用域隔离 HMAC，不存明文；共用准入入口不查询 User。按固定键顺序加锁，锁后取时、当前读统计并写入每个维度的尝试；覆盖邮箱60秒、邮箱15分钟3次和 IP 15分钟10次。拒绝请求计入滚动次数但不延长60秒，初次发送只影响邮箱冷却，不计 resend 配额。无效邮箱仍记录 IP；准入不等于创建账户、签发令牌或发信。
- 限流计数必须在独立根事务提交后才进入邮件事务；拒绝外层事务包裹，避免后续入队失败抹掉计数。既有键先查再锁，新键竞争由 UNIQUE 解决；死锁、锁超时或键竞争引发的可重试失败仅重试已回滚的整个准入事务，最多3次，不重试邮件或结果不明的提交。
- `config/initializers/filter_parameter_logging.rb` 增加 `subject_digest`；限流 SQL 使用局部日志屏蔽，数据库异常只记录异常类并转换为无 SQL／cause 的固定错误，不全局关闭 SQL 日志。邮件和其他令牌链路的日志验证仍留后续实施。
- `test/models/` 下新增令牌、约束、限流和并发测试；`test/support/verification_test_support.rb` 提供定向数据清理、独立连接、线程栅栏和超时恢复。新增 `test/integration/email_verification_foundation_test.rb` 验证只读 GET、带 CSRF 的 POST 与提交时重检，使用未挂载到应用的独立测试 Controller／Route；其路径、JSON、HTTP 状态或脱敏展示不成为正式接口／UI 决定。
- `script/verify_m2_schema.rb`：显式 `--execute`、测试环境、目标地址／账号、MySQL8.4、表清单、迁移版本及全业务表为空的守卫；只对空测试库执行结构往返。不 drop 整个数据库、不关闭 FK、不处理开发数据。原 M1 脚本保留，仅用于其匹配基线，不能用于当前 M2 库。
- 本计划仅记录开发 Agent 拥有的实施和测试证据；未自动调用维护 Skill 或修改其他正式文档。

令牌测试中的 `token_for` 直接创建“已经签发”的夹具，不能当作正式签发服务；`generate_secret` 仅生成随机值。本批没有注册 Controller、令牌轮换／enqueue 流程、Mailer 或 Job，不得直接以 Model 的 `create!` 拼接真实 resend。

#### 数据库执行与结构往返

执行前开发／测试库均为 M1 基线且无业务数据。在获批准的正常本地执行上下文，沿用原连接及 TLS 配置，限定 `127.0.0.1:3307`、`birding_app` 和开发／测试两库，应用三条新 Migration 并生成 Schema，两库版本均为 `20260831000001`～`20260831000005`。

空测试库实际完成 M2-only down 到 M1 → up，确认 M1 表保留；另按依赖顺序回滚全部业务表，再从 `schema.rb` 全新加载五表。比较引擎、列类型／精度／NULL／默认／collation、索引、CHECK、FK 和版本，全部一致；沿用12.5中仅限 InnoDB 的 RESTRICT／NO ACTION 等价比较。没有在旧 FK 存在时依靠强制关闭约束加载 Schema。

最后只读复核：两库各5张业务表及2张 Rails 元数据表，五张业务表均0条，无测试数据残留；TLS 仍为 TLS1.2／ECDHE-RSA-AES256-GCM-SHA384。未修改 MySQL5.7、未删除开发数据、未执行 Git add／commit／push。

#### 命令与结果

| 命令／检查 | 最终结果 |
| --- | --- |
| `bundle exec ruby bin/rails test` | seed2453：85 tests、957 assertions，0 failures／errors／skips；本批新增37个测试 |
| `bundle exec ruby bin/rails test:system` | seed1824：13 tests、312 assertions，0 failures／errors／skips；为既有浏览器回归，不代表正式验证页面完成 |
| `bundle exec ruby bin/rails test test/models/verification_concurrency_test.rb --seed N` | N=201～205各10 tests／52 assertions，全部0 failures／errors／skips；是重复验证，不算50个新增测试 |
| `bundle exec ruby script/verify_m2_schema.rb --execute` | M2-only down/up 与五表 schema.rb 全新加载往返通过；加载后完整普通测试通过 |
| `bundle exec ruby bin/rails zeitwerk:check` | All is good，exit0 |
| `bundle exec rubocop --cache false --format simple` | 60文件、0违规，exit0 |
| `bundle exec brakeman --no-pager` | 79检查、0错误、0安全警告，exit0；Windows提示不支持fork但扫描完成 |
| `git diff --check` | 通过；未执行add／commit／push |

完整普通＋System Test 合计98个、1269个断言，0失败、错误或跳过；并发5轮单独计数。

首轮新增测试30个／237断言、2失败／1错误／0跳过，如实发现：Rails 返回 boolean 默认值为 `false` 而非测试预期的字符串 `"0"`；重复创建已有共享 IP 键导致锁升级死锁；mysql2 在调试 SQL 中内联限流摘要，参数过滤不足以保护日志。分别修正测试类型判断、已有键查找与整事务有限重试、局部 SQL 日志及安全错误转换。随后同组30个／242断言全通过，并增加重试／失败回滚、真实请求和锁等待期间过期／冷却跨边界测试，得到最终85个普通测试结果。没有删除、跳过或弱化测试。

#### 并发证据、学习链路与剩余门槛

真实 MySQL 独立连接／线程验证包括：并发确认仅一次成功；消费 UPDATE 后注入错误同时回滚 User 与 token；相同新邮箱键和共享 IP 的竞争；三个邮箱拒绝请求以及第10个 IP 配额不能被并发绕过；双维度中途失败全部回滚；死锁后整体重试不重复计数及3次耗尽安全退出；User 锁等待期间跨过过期点必须拒绝；限流锁等待后用新时间判断60秒。使用实际事务／SQL、栅栏与故障注入，不用单线程模型测试代替并发，不以 sleep 猜测时序。

本批测试链路：测试 GET → 测试 Route／Controller → token 摘要查找 → User／token 当前状态锁定检查 → 只读测试响应；带 CSRF 的测试 POST → 相同状态重检 → 同事务更新 User 验证时间及 token 消费状态 → 测试响应，不登录。正式 View／Redirect 尚未接入。限流是未来邮件流程的独立前置步骤：服务器解析邮箱／IP → 锁定限流键 → 读取近期尝试 → 同时记账并提交 → 后续才查账户并处理发信。

**仍未实现／验证，不得以本批证据替代数据库设计14.6的完整 M2 故障矩阵：**

- M2-B：正式注册与重复注册处理、仅新账户的初次发信；User 锁内创建／替代 token 和 enqueue；enqueue 失败回滚后保留旧链接；enqueue 成功但事务失败的孤立 Job 不发送可用链接；两个并发真实 resend 最终仅一个 active token；worker 重新检查 User、token 最新／消费／替代／过期状态；Job payload 加密及隐私日志、重试和本地邮件验证。
- M2-C：正式 Route／Controller／ApplicationController、两步验证页面、locale、真实登录与空历史、受保护页面及安全返回路径、账户 System Test 和用户验收；失效 token、限流尝试及孤立键清理，连同 M1 过期 Session 次日维护须在阶段6结束前完成。
- 本批限流测试证明账户无关的共同入口，尚未证明最终页面／邮件全链路的账户状态不泄露；正式接口必须继续统一响应，不能把限流返回值直接当成账户存在与否。
- 密码辅助、Observation 及后续数据表、真实生产邮件、生产安全部署仍属原后续范围。

没有发现新的阻塞性产品或数据库问题。M2-B 可继续；当前还不能请用户验收完整“注册→验证→登录→空历史”闭环。

### 12.7 M2-B 实施与验证记录（2026-09-01）

**状态：注册、令牌实际签发／轮换、邮件 Job 与 worker 重检的后台流程已实现并验证；不是正式页面或整个 M2 完成。** 本批按认证、安全、事务和并发 HIGH 处理；验证稳定后的重复并发、静态检查和记录按 LOW 处理，未切换会话模型、未创建 subagent。未改变产品需求、MVP范围、ER图、表数量或依赖。

#### 实际改动与请求边界

- `AccountRegistration`：注册校验成功后先独立提交未验证 User，再独立提交邮箱 initial 准入证据，之后调用令牌发行；入队失败仍保留 User 与准入记录，不创建 Session。无效注册不写 User／限流／令牌；重复规范化邮箱不创建第二个 User、initial 记录或自动重发。
- `EmailVerificationRequest`：真实邮箱、已验证邮箱和未知邮箱使用 M2-A 的同一邮箱／IP 准入入口和统一公开结果；仅当前未验证 User 才进入发行。通过限流但入队失败仍不改变对外账户无关结果；正式 Controller 仍须使用 `request.remote_ip`，不能接收表单 IP。
- `EmailVerificationIssuer`：统一按 User → token 锁序，在 User 行锁事务中重读资格、将旧 active token 标为 superseded、创建新 active token，并立即调用专用 Job 入队。Job 显式关闭提交后延迟；只有返回实际已入队、无 enqueue_error 才提交。false、enqueue_error或异常均回滚新 token 与旧 token 替换，错误日志只记录异常类。
- `EmailVerificationDeliveryPayload`：队列只保存 User ID、token ID、locale与带用途、认证加密、按令牌期限过期的载荷；载荷内原始 secret 还会与标量参数及数据库摘要交叉核对。普通 Job 日志关闭参数输出。
- `EmailVerificationDeliveryJob`：先锁 User，再以锁定当前读重查 token；User不存在／已验证，token不存在／已替代／消费／过期，参数不一致、载荷篡改或过期时均退出。有效时复制最小邮件地址后结束事务，再交给邮件传输，不在数据库锁内等待。投递错误转换为无底层 cause 的固定错误，最多重试3次；每次重试都重新读取当前状态，不恢复旧 token 或延长期限。
- `EmailVerificationMailer` 与中日文 multipart 模板：本地 test adapter 下生成15分钟确认邮件，不发送到外部。正文不包含完整邮箱；原始 secret 只出现在确认链接，邮件处理日志被局部屏蔽。`/email-verification` 是为 M2-C 准备的当前代码路径，尚未挂载正式 Route／Controller，精确路径和邮件微文案不因本批测试通过升级为正式 UI 决定。
- 新增 Payload、注册、统一重发、发行、Mailer、Job及真实并发测试；扩展定向测试清理与兼容 Minitest 6 的可恢复方法替换辅助。未修改数据库结构或 Migration。

本批后台链路：未来注册 Controller → `AccountRegistration` 保存 User → `VerificationRateLimiter.initial` 独立记账 → `EmailVerificationIssuer` 锁 User、轮换 token并实际入队 → `EmailVerificationDeliveryJob` 重新锁定／校验 → 释放数据库事务 → `EmailVerificationMailer` 交给本地邮件传输。未来重发 Controller → `EmailVerificationRequest` 统一限流 → 只有符合资格的 User 进入同一发行链路。当前没有正式 Route／Controller／View／Redirect，因此不能由用户操作或验收。

#### 高风险验证证据

- false、enqueue_error和抛异常三种入队失败均回滚新 token，旧链接保持 active；initial／resend 准入证据因已独立提交而保留。
- 模拟 adapter 已记录 Job 后发行事务回滚：数据库不存在新 token，孤立 Job 执行后退出且不发送，旧链接继续有效。
- 两个独立 MySQL 连接并发发行，最终只有一个 active token；两个 Job 都运行时仅当前 token 的 Job 发信。固定 seed 301～305 各4 tests／17 assertions均通过。
- worker 在发行事务提交前开始、等待 User 锁后重读已提交状态；另验证交给邮件传输时数据库事务已结束。
- superseded、consumed、expired、User已验证、记录删除、标量参数不匹配、载荷篡改或过期全部不发送。
- unknown、已验证与未验证邮箱的统一请求均走相同准入和公开结果；只有未验证 User 创建业务 token。正式页面／HTTP的响应时间和可观察差异仍由 M2-C 做端到端检查。
- 加密队列载荷不含可见原始 secret／邮箱；Job与邮件日志不出现原始 secret、加密载荷、收件邮箱或底层SMTP错误。投递失败固定错误最多重试3次。

首轮20 tests／67 assertions出现1 failure／9 errors：测试事务与限流根事务冲突、`assert_enqueued_with`返回值误用、Minitest 6不再提供旧mock helper以及过期测试写入只读字段。改为真实非事务数据库测试、显式结果捕获、自有可恢复故障注入和只推进时钟。扩展并发后23 tests／140 assertions出现1 failure／2 errors，修正测试方法替换的接收者及有限重试执行方式。安全日志调整后24 tests／123 assertions出现1 failure／4 errors，发现false不是nil，不能用安全导航读取enqueue_error；同时把“锁外投递”移到无外层测试事务的真实连接验证。没有删除、跳过或弱化测试。最终本批24个新增测试／157个断言全部通过。

#### 命令与结果

| 命令／检查 | 最终结果 |
| --- | --- |
| `bundle exec ruby bin/rails test` | seed32686：109 tests、1114 assertions，0 failures／errors／skips；较 M2-A 新增24 tests／157 assertions |
| `bundle exec ruby bin/rails test:system` | seed65382：13 tests、312 assertions，0 failures／errors／skips；既有静态浏览器回归，不是正式账户页面验收 |
| `bundle exec ruby bin/rails test test/models/email_verification_delivery_concurrency_test.rb --seed N` | N=301～305各4 tests／17 assertions，全部0 failures／errors／skips；重复验证，不算20个新增测试 |
| `bundle exec ruby bin/rails zeitwerk:check` | All is good，exit0 |
| `bundle exec rubocop --cache false --format simple` | 73文件、0违规，exit0 |
| `bundle exec brakeman --no-pager` | 79检查、0错误、0安全警告，exit0；Windows提示不支持fork但扫描完成 |
| `git diff --check` | 待最终复核；未执行add／commit／push |

完整普通＋System Test 合计122个、1426个断言，0失败、错误或跳过；并发5轮单独计数。

#### 剩余 M2-C 门槛

- 接入正式注册、重发、两步验证、登录、受保护空历史和退出的 Route／Controller／Rails View／Redirect；真实表单启用 CSRF、使用可信 `request.remote_ip`，接入加密待验证邮箱状态、语言 Cookie与安全返回路径。
- 正式页面必须保持未知／已验证／未验证邮箱的响应与可观察反馈一致；不能把内部 `accepted`、`ineligible` 或入队结果直接暴露为账户状态。注册已创建但初次邮件未入队的专属结果只适用于刚创建的账户。
- 把邮件链接接到正式两步验证入口，并按已确认结果体系处理有效、过期、无效、已消费、被替代和已验证；精确路径、微文案、提交后焦点与字段保留在 M2-C 按 owning document 处理。
- 实现失效 token 7天、attempt 24小时、孤立限流键及过期 Session 次日清理；完成正式账户 Integration／System Test、双语浏览器流程和用户验收。
- 当前只用 test adapter 验证，不发送真实邮件；开发 async adapter支持本协议但进程退出可丢任务的风险已确认。生产队列、真实供应商、发件域名、HTTPS URL、Secret轮换和投递可观测性仍延后到部署准备。

没有新的阻塞性产品、数据库或安全决定。M2-C可以继续；阶段6和第一个纵向切片仍未完成。

### 12.8 M2-C 实施与验证记录（2026-09-01）

**状态：正式账户页面、完整浏览器闭环与维护清理已实现并通过机械验证；阶段6等待用户验收。** 认证、安全、隐私与端到端串联按 HIGH 处理；核心实现通过后，并发重复、质量扫描、数据清理复核与记录降为 MEDIUM。未切换当前会话模型、未创建 subagent。未改变产品需求、MVP范围、ER图、表数量、Migration或依赖。

#### 实际改动与请求边界

- `ApplicationController` 接入 M1 `Authentication` 与 locale 选择：显式的有效 locale 参数写入加密、HttpOnly、SameSite=Lax 的浏览器 Cookie；没有显式选择时先读 Cookie，再把浏览器首选 `zh*` 映射为简体中文，其余映射为日文。开发环境静态预览显式允许匿名访问，避免被正式认证边界误伤。
- 正式账户 Route／Controller／Rails View 接通注册、统一重发、两步邮箱验证、登录、退出、受保护空观察历史与设置页；复用 B′ 已验收的 Rails partial、CSS 与 I18n 结构，没有引入新前端框架或重做视觉方向。
- 无效注册不写业务数据，密码字段不回显，邮箱在服务入口先规范化；重复注册不创建第二个 User、不自动重发。注册成功保留未验证 User，并用加密、HttpOnly、一天有效的临时 Cookie 记住当前浏览器的待验证邮箱。
- 重发 Controller 始终使用服务器取得的 `request.remote_ip`，未知、已验证和未验证邮箱进入同一 M2-A 限流入口并显示账户无关结果；只有符合条件的未验证 User 进入 M2-B token 发行。内部详细结果不作为账户存在状态公开。
- 邮件链接正式指向 `GET /email-verification`。GET 只检查 token并显示脱敏邮箱；POST 再锁定并确认，成功时原子验证 User、消费 token，不创建 Session。POST 使用标准 Post／Redirect／Get，结果状态暂存在加密 Rails session，避免 Turbo 成功提交后停留在旧确认页面。
- 登录继续使用 M1 的锁外慢哈希、锁内摘要／资格重检协议。凭证错误显示统一失败；凭证正确但未验证不创建 Session，并提供重发入口。认证前访问的 GET HTML 站内路径暂存在加密 Rails session；登录后只接受合法站内相对路径，否则进入空观察历史。退出只删除当前数据库 Session。
- 空观察历史与设置页需要有效 Session；设置页显示真实当前邮箱和浏览器语言选择。Observation 新建、密码重置与修改密码仍保持不可操作／延后状态，没有创建观察数据或扩大当前切片。
- 新增 `MaintenanceCleanup` 与 `maintenance:cleanup`：删除本日之前已过期的 Session、保留期超过7天的失效／过期验证 token、超过24小时的限流尝试，以及删除尝试后形成的孤立限流键。删除边界用真实数据库记录测试，任务不引入额外调度或基础设施。

完整用户链路：浏览器提交注册表单 → Route → `RegistrationsController` → `AccountRegistration`／限流／token发行 → 五张既有账户表 → 结果页；邮件 Job 重检后生成本地验证邮件 → GET确认页只读检查 → POST确认在事务中验证User并消费token → 登录Controller调用`Session.authenticate` → 数据库Session＋加密Cookie → 受保护空历史；退出请求只删除当前Session并返回登录页。主要校验点是服务器密码规则、规范化邮箱唯一性、token当前状态、User资格、CSRF、站内返回路径和受保护页面认证。

#### 测试、失败修正与验证证据

- 新增正式账户 Integration Test、完整浏览器 System Test、维护清理测试及测试数据清理辅助；既有静态 System Test继续回归14个页面／流程状态。CSRF 测试明确验证注册、重发与登录在开启防伪保护时拒绝缺少 token 的请求。
- 首轮全量普通测试109个／1059断言出现9个失败：全局认证正确拦截了既有测试专用Controller的公开探针。仅为该测试Controller声明匿名访问，保留其自身受保护页面与CSRF断言，没有放宽正式Controller或删除测试。
- 定向测试随后发现两项测试构造问题：Session测试把到期时间写到创建时间之前，正确触发数据库CHECK；清理测试在同一User下直接创建多个active token，正确触发组合唯一。测试数据改为符合真实约束的历史时间与独立User，不修改生产约束。
- 浏览器测试先后发现邮件链接解析调用错误、Turbo 对成功表单直接render不会替换旧页面，以及断言使用了不存在的示例文案。分别改正Nokogiri取值、把确认成功改为Post／Redirect／Get，并让断言读取已有I18n文案；没有通过延长等待、跳过或弱化测试取得通过。

| 命令／检查 | 最终结果 |
| --- | --- |
| `bundle exec ruby bin/rails test` | seed1422：120 tests、1259 assertions，0 failures／errors／skips；较 M2-B 新增11 tests／145 assertions |
| `bundle exec ruby bin/rails test:system` | seed18084：14 tests、330 assertions，0 failures／errors／skips；新增1个完整账户浏览器流程／18断言 |
| 3份认证／验证并发测试，固定5个seed | 104729、130363、155921、181081、206369各19 tests／88 assertions，全部0 failures／errors／skips；重复验证，不并入新增测试数 |
| `bundle exec ruby bin/rails zeitwerk:check` | All is good，exit0 |
| `bundle exec rubocop` | 86文件、0违规，exit0；沙箱缓存目录不可写但不影响完整扫描 |
| `bundle exec brakeman --no-pager` | 79检查、0错误、0安全警告，exit0；Windows提示不支持fork但扫描完成 |
| 两库只读收尾复核 | MySQL 8.4.10；TLS cipher `ECDHE-RSA-AES256-GCM-SHA384`；开发／测试库的5张业务表各0行 |
| `git diff --check` | 通过；未执行add／commit／push |

完整普通＋System Test 合计134个、1589个断言，0失败、错误或跳过；并发5轮单独计数。M2-C没有新增或修改 Migration，开发／测试库仍只有 M1＋M2-A 的五张账户业务表。

#### 验收与剩余边界

- 自动测试已证明本地 test adapter 下的“注册→邮件→只读确认→提交验证→手动登录→受保护空历史→语言切换→退出”闭环；用户仍需在本地页面验收业务行为和可见反馈，阶段6在此之前保持`待验收`。
- 正式路径命名、当前中日文服务器反馈微文案、确认结果使用Post／Redirect／Get、加密临时Cookie键名与维护类／任务名称是本轮工程实现事实，不因代码出现自动升级为不可调整的产品或UI决定。
- 密码重置／修改密码、Observation业务与表、真实邮件服务、生产Job持久化与调度、生产TLS身份验证和部署仍按既有计划延后。当前没有新的阻塞性产品、数据库或安全问题。

## 13. 后续纵向切片候选

**总体决定状态：`provisional`**

### 13.1 Observation 核心闭环

- Observation 与 User 归属；
- 选择有效轮廓；
- 首次保存；
- 空／非空历史；
- 详情与重新打开；
- 当前用户作用域授权。
- 同批接入PartImpression及其最低有效性、ActivityLocationSelection与可选行为；首次保存不得出现仅轮廓记录。

### 13.2 SVG 与摘要渐进增强

- 复用上一切片已有的部位、颜色、特征、确定程度、自由文字、行动位置与行为数据；
- 最低保存条件已在Observation首次保存时实现，本阶段不补建这一前置条件；
- 服务器生成 inline SVG 与本地化文字摘要；
- 普通 Rails 提交 → Turbo Frame → Stimulus 自动触发的渐进预览。

正式实施前必须先确认轮廓、颜色、特征和行动位置的最终配置。

### 13.3 鸟种确认、账户辅助与设置

- BirdCandidate 与最多三个候选；
- 最终鸟名和派生识别状态；
- 删除、修改、撤销和未提交输入保护；
- 忘记密码、密码重置和登录后修改密码；
- 设置页真实邮箱、语言和退出行为。

密码重置令牌具体结构见database-design；本阶段才按M5实施，密码重置与修改密码后的Session失效规则不变。

### 13.4 全 MVP 回归与本地验收

- 中日文完整闭环；
- 个人数据授权和越权访问；
- 数据库约束、事务和边界状态；
- 邮件、Session、令牌和限流安全；
- 移动端主流程、软键盘和必要的多浏览器检查；
- 全量测试、RuboCop、Brakeman 和浏览器验收；
- 进入部署准备前的剩余问题清单。

## 14. 每阶段工作方式

### 14.1 开始前

1. 检查当前正式文档和 Git 基线；
2. 明确本阶段目标、包含与不包含范围；
3. 区分已确认、暂定、未确认、延后、否决、AI 建议和 observed-only；
4. 列出预计修改文件及用途；
5. 说明数据流、Rails 学习重点和测试方案；
6. 检查是否触发 2.3 节升级条件；没有触发时由开发 Agent 继续执行，不等待常规工程审批。

### 14.2 实施时

1. 优先使用 Rails 标准目录、生成器和约定建立可读基线；
2. 逐文件审查生成结果，不把生成器输出直接视为完成；
3. 重要业务规则同时考虑 Model Validation 和必要的数据库约束；
4. 个人数据通过当前用户关联集合访问；
5. 先运行最小相关测试，再运行全量回归；
6. 不删除、跳过或弱化测试以获得通过结果。

### 14.3 完成时

1. 根据阶段类型和完成标准更新状态；用户可见业务阶段标记为“待验收”，纯工程设计阶段在必要检查通过且无待处理升级项后可以直接完成；
2. 记录实际修改和验证命令；
3. 报告测试数量、断言、失败、错误、跳过和覆盖缺口；
4. 报告安全、授权、数据库和浏览器检查结果；
5. 说明与静态前端或高保真基线的差异；
6. 用户可见业务行为由用户验收后再标记为“已完成”；常规工程设计不要求用户逐项审批；
7. 在重要后端纵向节点，用易理解的方式说明用户操作 → Route → Controller → Model／必要流程对象 → Database → View／Redirect 的核心链路，以及主要校验和授权点；
8. 只有产生正式事实变化时才输出文档维护交接单；
9. 未经明确要求不执行 `git add`、`git commit` 或推送。

## 15. 跨阶段测试与质量门槛

| 层级 | 主要职责 |
| --- | --- |
| Model Test | Validation、关联、派生状态、业务边界 |
| Integration Test | Route、Controller、Session、授权、表单结果和重定向 |
| Mailer／Job Test | 邮件内容、入队、locale 和不发送真实邮件 |
| System Test | 用户关键闭环、JavaScript 增强和未保存保护 |
| Database Test | 外键、唯一性、索引相关行为、事务和并发边界 |
| Security Check | 越权访问、账户枚举、令牌、Session、限流和日志泄露 |
| Static Quality | Zeitwerk、RuboCop、Brakeman、`git diff --check` |

每次交付至少报告：

- 实际执行命令；
- tests 与 assertions；
- failures、errors 与 skips；
- 未执行的测试及原因；
- 已知覆盖缺口；
- 用户可执行的验收步骤。

## 16. 文档同步与交接规则

- 本计划只更新实施阶段、进度、依赖和验证证据；
- ER 图和物理 Schema 细节记录在 [database-design.md](database-design.md)；
- 新的产品决定交由 Project Maintainer 判断是否同步 `requirements.md` 或 `mvp-scope.md`；
- 新的架构决定交由 Project Maintainer 判断是否同步 `technical-decisions.md`；
- 当前阶段、阻塞或完成状态变化交由 Project Maintainer 判断是否同步 `current-status.md`；
- 正式后端接入改变 Rails 前端数据流或维护方式时，交由 Project Maintainer 判断是否同步 `frontend-implementation-guide.md`；
- 新增、删除或改变重要文档职责时，交由 Project Maintainer 判断是否同步 `DOCUMENTS-GUIDE.md` 和 `AGENTS.md`；
- 实施或讨论产生实质性正式事实变化时，开发 Agent 在对话末尾输出一次性交接单，不自行决定最终文档归属。

## 17. 进度日志

| 日期 | 阶段 | 状态变化 | 证据与说明 |
| --- | --- | --- | --- |
| 2026-08-17 | 计划确认 | 新增 | 用户确认按照后端设计、数据库设计、Migration 规划和纵向切片的流程分阶段进行 |
| 2026-08-17 | 文档结构 | 已确认 | 用户确认采用后端开发主计划与独立数据库设计文档的两层结构 |
| 2026-08-31 | 阶段 1 | 进行中 | 六个业务模块及辅助职责边界已确认；数据流、授权／信任边界、数据分类和阶段验收仍待完成 |
| 2026-08-31 | 阶段 1 | 已完成 | 主要请求流、授权与信任边界、数据状态分类及下一阶段未决问题已由用户确认；未创建 Model、Migration 或正式 ER 图 |
| 2026-08-31 | 后端协作方式 | 已确认 | 从阶段 2 起采用默认 Agent 自主、关键决定升级、机械验证和重要纵向节点 walkthrough；阶段 2～5 暂定作为短冲刺连续推进 |
| 2026-08-31 | 阶段2～3 | 交付核查 | 已形成ER、10表数据字典、约束、查询、事务与生命周期；用户接受邮件／隐私保留／长度三项边界；未创建业务表 |
| 2026-08-31 | 阶段4 | 本地验证完成 | 相同TLS配置在非沙箱成功；Rails普通与System Test共28个／753断言全通过，前后均无业务表 |
| 2026-08-31 | 阶段5 | 交付核查 | 完成M1～M5依赖、回滚及测试映射；修正Observation首次保存必须包含部位的实施依赖 |
| 2026-08-31 | 阶段2～5 | 已完成 | 全需求章节映射核查、26项只读SQL核查、37项文档结构／链接／ER／改动范围检查通过；业务实现、实际建表及约束回归仍按后续切片执行 |
| 2026-08-31 | 阶段6／M1 | 工程基础验证通过 | 开发／测试库执行2个Migration；User、Session、Current与未挂载正式页面的Authentication基础；48个普通测试／666断言、13个System Test／312断言全通过；M2及整切片验收未完成，详见12.5 |
| 2026-08-31 | 阶段6／M2-A | 令牌与限流基础验证通过 | 开发／测试库新增3表；确认事务、共用限流、SQL约束、真实并发及结构往返通过；85个普通测试／957断言、13个System Test／312断言全通过；注册／邮件与正式页面留M2-B／C，详见12.6 |
| 2026-09-01 | 阶段6／M2-B | 注册与邮件后台流程验证通过 | 注册独立提交、真实令牌轮换、加密Job载荷、worker状态重检、孤立Job、有限重试与隐私日志通过；109个普通测试／1114断言、13个System Test／312断言全通过；正式页面和维护清理留M2-C，详见12.7 |
| 2026-09-01 | 阶段6／M2-C | 实现与机械验证通过，待用户验收 | 正式注册／重发／两步验证／登录／空历史／设置／退出、locale、安全返回路径及维护清理接通；120个普通测试／1259断言、14个System Test／330断言全通过；详见12.8 |

## 18. 当前阻塞与下一步

### 当前阻塞

无已知 M2 或阶段6工程阻塞。数据库仍为既有五表；M1、M2-A、M2-B、M2-C 及完整浏览器闭环、CSRF、并发、维护清理和质量扫描均已通过。阶段6当前只等待用户验收业务行为与页面反馈，不把机械测试通过替代用户验收。

### 当前下一步

请用户本地验收阶段6的“注册→验证→登录→空历史→退出”闭环和中日文反馈。验收通过后，阶段6可由 Project Maintainer 同步为已完成，再按既有计划进入阶段7 Observation 核心闭环；密码重置／修改密码、Observation表与正式部署仍在后续批次。将 M2-A～C 的统一实施状态、验证证据和 observed-only 实现细节交给 Project Maintainer 判断同步范围，本任务不自动调用维护Skill。

### 18.1 阶段2～5完成审计

| 目标 | 当前证据 | 不应误读为 |
| --- | --- | --- |
| 完整领域模型／ER／生命周期 | database-design第7～8节；10实体、8关系、13个需求章节映射 | 已创建Model或已实现业务 |
| 完整物理设计／完整性／安全 | 第9～15节字段、索引、约束与协议；用户接受三项风险问题；26项只读SQL检查 | 已执行DDL或已验证所有运行时并发 |
| TLS与完整本地回归 | 本计划10.2～10.4；Rails连接、28测试／753断言、质量扫描 | 已配置生产TLS身份验证或已覆盖认证功能 |
| 迁移批次与首任务 | database-design第16节与本计划11.2～11.4，M1～M5及回滚／测试映射 | 一次性建表或已经开始阶段6 |

37项文档检查核对两份文档章节连续、代码围栏成对、本地Markdown链接存在、ER节点／边数、10表清单，以及Git只修改这两份文件。属于轻量交付核查，不建立额外文档治理工具，也不是图像渲染或业务测试。

### 18.2 只读Rails连接复现

在仓库根目录的正常本地PowerShell执行；在Codex沙箱遇到同类Schannel错误时，先申请相同命令的非沙箱对照，不改TLS选项。不输出密码。

```powershell
@'
abort "Preview bypass must be absent" if ENV["STATIC_FRONTEND_PREVIEW"] == "1"
require_relative "config/environment"
%w[development test].each do |environment|
  config = ActiveRecord::Base.configurations.configs_for(env_name: environment, name: "primary")
  settings = config.configuration_hash
  abort "Unexpected target" unless settings[:host] == "127.0.0.1" &&
    settings[:port].to_i == 3307 && settings[:username] == "birding_app" &&
    settings[:database] == "birding_app_#{environment}"
  ActiveRecord::Base.establish_connection(config)
  ActiveRecord::Base.connection_pool.with_connection do |connection|
    p environment: environment,
      server: connection.select_one("SELECT VERSION() AS version, @@port AS port, DATABASE() AS db"),
      tls: connection.select_all("SHOW SESSION STATUS WHERE Variable_name IN ('Ssl_cipher','Ssl_version')").to_a,
      tables: connection.tables,
      migrations: connection.select_value("SELECT COUNT(*) FROM schema_migrations")
  end
  ActiveRecord::Base.connection_pool.disconnect!
end
'@ | bundle exec ruby -
```

26项只读SQL检查矩阵：每个库分别比较精确排序规则下的`Bird/bird`、`a/a空格`、`e/é`、`é/e+组合重音`应不同，`鳥/鳥`应相同；再对database-design第10.4节原式代入8种令牌状态。合法3种为当前1／无失效、NULL／有时间／consumed、NULL／有时间／superseded；非法5种为三个NULL、当前1但已消费、NULL／有时间／无原因、槽2、未知失效原因。实际SELECT均返回预期0或1而非NULL；未创建临时或业务表。
