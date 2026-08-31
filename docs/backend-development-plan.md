# 观鸟 Web App｜后端开发计划与进度

> 文档性质：Rails 后端开发、纵向切片实施与验收跟踪文档  
> 当前分支：`codex/backend-development`  
> 建立日期：2026-08-17  
> 当前阶段：阶段 2～5 已完成设计与本地基础设施验证；业务切片阶段 6 尚未开始
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
| 6 | 纵向切片 1：可登录的空观察历史 | 阶段 5 | 未开始 | `confirmed` |
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
| M1／纵向切片1 | users → sessions | 设计完成后作为阶段6首个任务 |
| M2／纵向切片1 | email_verification_tokens；rate_limit_keys → send_attempts | M1后接入，共同完成首个纵向切片 |
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

**状态：`未开始`**  
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

## 18. 当前阻塞与下一步

### 当前阻塞

无已知阶段2～5阻塞。Windows沙箱Schannel问题仍可复现，但获批准的正常本地执行已能完成Rails数据库与全部现有测试；不因此修改TLS策略。生产安全、正式鸟类配置和业务代码测试仍在各自后续阶段处理。

### 当前下一步

阶段6从M1开始；本轮目标止于阶段5，不自动生成或执行业务Migration。将新确认的规则、设计交付和TLS证据交给Project Maintainer同步其他正式记录，本任务不自动调用维护Skill。

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
