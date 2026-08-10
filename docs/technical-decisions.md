# 观鸟 Web App｜技术决策

> 文档状态：已确认技术路线
> 记录日期：2026-08-10
> 本文档只记录用户已经明确确认的技术与实施决定。产品能力以 `requirements.md` 为准，MVP 边界以 `mvp-scope.md` 为准，UI 状态以 `ui-design.md` 为准。
> 尚未经过安装、运行或测试验证的兼容性结论会明确标记为“实施时验证”，不得视为已经验证通过。

## 1. 总体架构

- 应用采用 **Rails 模块化单体**。
- 不建立独立 SPA、独立前端仓库或仅提供 JSON API 的后端项目。
- 前后端通过清晰的目录、职责和文件边界保持可独立修改，但共享同一个 Rails 应用、运行时和部署单元。
- Rails 后端学习仍是项目的主要技术重点；前端实现以可理解、可维护和足够完成 MVP 为准。

### 1.1 代码职责边界

- Model：数据关系、验证和核心业务规则。
- Controller：HTTP 请求、授权范围和流程编排，避免承载复杂业务规则。
- Service：只在注册验证、跨步骤保存等流程确实跨越多个对象时使用，不为简单 CRUD 创建形式化服务层。
- Presenter：组织文字摘要和 SVG 渲染所需的派生数据。
- Mailer 与 Job：分别负责邮件内容和异步执行。
- Rails View、局部模板、Stimulus Controller、CSS、I18n 和配置数据分别放在各自标准目录中。

MVP 不引入 Java 风格的 Repository／DAO 层，不引入 Pundit、CanCanCan 或 ViewComponent。个人数据访问通过当前用户作用域限制，例如从 `Current.user.observations` 查找记录，而不是直接按全局 ID 查找。

## 2. 开发与运行环境

- 开发环境使用 **Windows 原生环境**，不以 WSL2、Docker 或完整开发容器作为默认开发方式。
- Ruby：**4.0.6**。
- Rails：**8.1.x**。
- 数据库：**MySQL 8.4 LTS**。
- 第一阶段目标是先在本地完整运行、测试和演示；本地闭环完成后再准备部署。

以上版本组合必须在项目初始化时通过实际安装、依赖解析、应用启动、数据库连接和测试运行验证。发现兼容问题时先报告具体证据，不得自行更换已确认版本。

## 3. Rails 初始化配置

项目采用普通 Rails 单体应用，并使用以下初始化方向：

- MySQL 数据库适配；
- Rails Views 与 ERB；
- Importmap；
- Propshaft；
- Turbo；
- Stimulus；
- Minitest；
- 保留 Action Mailer 和 Active Job。

MVP 初始化时跳过当前不需要的 Action Mailbox、Action Text、Active Storage、Action Cable 和纯 JSON API 组件。第一阶段不创建正式 Docker 和部署配置。

## 4. 前端实现路线

- 使用 Rails Views、HTML、CSS、Turbo、Stimulus 和少量普通 JavaScript。
- 页面导航、表单提交和服务器渲染优先使用 Rails 与 Turbo 的标准能力。
- Stimulus 只负责局部交互，例如语言菜单、编辑状态、预览触发和未保存修改提醒。
- 普通 JavaScript 只用于浏览器级能力或 Stimulus 不适合承载的极小逻辑。
- MVP **不引入 Vue**，也不引入 React 或独立前端构建体系。

当前交互主要是表单、局部替换、状态提示和结构化输入，没有达到需要 Vue 组件状态树或独立客户端数据层的复杂度。若以后确实出现无法由 Turbo 与 Stimulus 清晰维护的局部交互，必须重新说明需求和代价并取得确认，不能直接加入 Vue。

## 5. 抽象鸟类印象图

- 抽象图采用服务器生成的 **inline SVG**。
- SVG 由版本控制中的轮廓和部位映射配置，加上用户结构化输入生成。
- 预览请求不保存 Observation 或 PartImpression。
- Stimulus 触发预览请求，Turbo Frame 替换抽象图和本地化文字摘要。
- 实施顺序采用渐进方式：普通 Rails 预览提交 → Turbo Frame 局部替换 → Stimulus 自动触发。
- 数据库只保存结构化观察数据，不保存生成后的 SVG 文件、SVG 字符串或文字摘要。
- 历史和详情页面需要展示时，根据已保存的结构化数据重新生成 SVG 与摘要。

MVP 不采用 Canvas 作为主生成方案，也不使用 HTML/CSS 拼装完整鸟体。SVG 更适合少量固定轮廓、可定位身体部位、服务器渲染、响应式缩放和无损缩略图的当前需求。

## 6. 账户、认证与授权

- 使用 Rails 8 第一方 authentication generator 作为基础。
- 密码使用 `has_secure_password`。
- 登录状态使用数据库 Session 记录和 Rails Cookie，不采用 JWT。
- 在基础认证之上实现注册和邮箱验证。
- 不引入 Devise、OAuth 或第三方登录。
- 邮箱验证链接有效期为 **15 分钟**。
- 忘记密码重置链接有效期为 **15 分钟**。
- 邮箱验证成功和密码重置成功后均返回登录页，由用户手动登录，不自动创建登录会话。

### 6.1 重新发送验证邮件

重新发送验证邮件支持两个入口，共用同一后端流程：

1. 注册结果页可以直接重新发送；待验证邮箱暂存在加密的浏览器 Session 中。
2. 用户也可以重新输入邮箱请求发送。

两个入口都返回不泄露账号是否存在的通用结果，并接受频率限制。新的验证邮件可以重新生成有效链接；旧链接是否仍可使用由服务端令牌有效性规则统一控制，不依赖前端页面状态。

### 6.2 个人数据授权

- 所有 Observation 必须属于 User。
- 读取、编辑和更新观察记录时必须从当前用户的关联集合中查找。
- MVP 不引入角色权限系统或管理员授权框架。

## 7. 邮件与后台任务

- 邮件通过 Action Mailer 生成，并使用 `deliver_later` 入队。
- 开发环境使用进程内异步执行，并用 `letter_opener` 在 Windows 默认浏览器中打开实际触发的邮件。
- 开发环境同时保留 Rails Action Mailer Preview，用于独立检查邮件模板。
- 测试环境使用 Active Job 和 Action Mailer 的 test adapter，不打开浏览器，也不发送真实邮件。
- 生产环境使用 Solid Queue 和外部邮件服务。
- MVP 不引入 Redis，也不启用 Action Mailbox。

生产邮件服务供应商、发件域名和正式投递配置留到部署准备阶段决定。

## 8. 显示语言与时区

- 使用 Rails I18n，支持 `zh-CN` 和 `ja`。
- 用户主动选择的显示语言保存在签名持久化浏览器 Cookie 中，不写入 User 数据库记录。
- 首次访问且没有语言 Cookie 时读取浏览器语言。
- 浏览器语言既不是简体中文也不是日文时，默认回退到 **日文**。
- 切换语言后当前页面立即生效。
- 邮件任务在入队时继承当前 locale，避免异步执行时丢失邮件语言。
- 数据库存储 UTC 时间；界面按 `Asia/Tokyo` 显示。
- Observation 的正式记录时间是第一次成功保存的时间，后续编辑不改变该时间。

## 9. 数据库与本地 MySQL 共存

### 9.1 应用数据库约定

- 开发库和测试库分离，默认名称为 `birding_app_development` 与 `birding_app_test`。
- Rails 使用专门的非 root MySQL 用户。
- 数据库凭据通过环境配置提供，不提交到 Git。
- 使用 InnoDB、`utf8mb4` 和 MySQL strict mode。
- 数据库结构由 Rails Migration 管理，使用 Rails 默认 `schema.rb`。
- 核心业务数据使用关系结构，不使用 MySQL ENUM、触发器、存储过程或核心 JSON 大字段。
- MVP 不引入软删除、审计表或版本历史表。
- 重要业务规则同时使用 Rails Validation 和必要的数据库非空、唯一、外键及索引约束保护。

### 9.2 保留现有 MySQL 5.7 数据

- 现有 MySQL 5.7 服务及其中需要保留的数据不升级、不覆盖、不卸载。
- MySQL 8.4 采用并行安装，使用独立 Windows 服务、独立数据目录和独立端口；当前规划服务名为 `MySQL84`、端口为 `3307`。
- Rails 项目只连接新的 MySQL 8.4 实例。
- 安装 MySQL 8.4 前先备份现有 MySQL 5.7 数据。
- 本项目不需要把现有 5.7 数据迁移到 8.4；备份方法、位置和恢复验证在安装前单独执行和记录。

## 10. 最小数据对象与关系

以下是概念级对象，不是 migration 或正式数据库 schema：

```text
User
├─ has_many Session
└─ has_many Observation
   ├─ has_many PartImpression
   ├─ has_many BirdCandidate
   └─ has_many ActivityLocationSelection
```

- **User**：邮箱、密码摘要、邮箱验证状态及账户时间信息。
- **Session**：登录会话，属于一个 User。
- **Observation**：属于一个 User，保存轮廓稳定键、首次保存时间、行为文字和最终鸟名等观察级数据。
- **PartImpression**：属于一个 Observation；每个实际记录的身体部位最多一条，保存部位键、主色键、补充色键、特征键、自由文字和确定程度。
- **BirdCandidate**：属于一个 Observation，保存一个用户自由输入的候选鸟名；业务规则限制最多三条。
- **ActivityLocationSelection**：属于一个 Observation，保存一个行动位置稳定键；业务规则限制最多两条。

轮廓、颜色、花纹／特征、行动位置及 SVG 映射属于受版本控制的策划配置，使用稳定键引用，不建立数据库字典表或 MVP 管理后台。

识别状态由候选鸟名和最终鸟名计算，文字摘要和 SVG 由结构化数据生成；这三类派生结果不单独持久化。

## 11. 测试与质量保障

- 使用 Minitest、Fixtures、MySQL 测试数据库和 Rails System Tests。
- 使用 RuboCop 做静态风格检查，使用 Brakeman 做 Rails 安全扫描。
- MVP 不引入 RSpec、FactoryBot、Jest 或 Vitest。
- Agent 负责测试设计、编写、运行和回归检查；用户负责根据测试报告和实际演示验收结果。
- Agent 不得通过删除、跳过或弱化测试来制造通过结果。
- 每次交付报告实际运行命令、测试数量、失败、错误、跳过项和已知覆盖缺口。
- AI 生成内容只有在运行、审查和测试后才能视为完成。

## 12. 分阶段交付

### 阶段 1：本地运行和演示

- 在 Windows 原生环境完成项目初始化、开发数据库、自动测试和本地演示。
- 使用本地邮件预览，不配置真实发信域名。
- 不要求域名、HTTPS、公开网络访问、Docker 或正式部署配置。

### 阶段 2：部署准备

- 确定 Linux 托管平台和生产 MySQL。
- 配置 Solid Queue worker、真实邮件服务、Secrets、CI、备份和监控。
- 补充生产环境运行与恢复说明。

### 阶段 3：公开部署

- 在本地 MVP 闭环通过验收后再执行。
- 域名、HTTPS、生产邮件投递和线上监控属于本阶段验收内容。

具体托管平台和邮件供应商尚未确认，不得在本地阶段提前写死。

## 13. 第一个纵向切片

第一个纵向切片确认为 **“可登录的空观察历史”**。

用户完成的流程：

1. 根据浏览器语言进入中文或日文注册页；
2. 使用邮箱和密码注册；
3. 在浏览器中打开验证邮件；
4. 在 15 分钟内完成邮箱验证，必要时重新发送；
5. 验证成功后返回登录页，不自动登录；
6. 手动登录并进入自己的空观察历史页；
7. 退出登录。

该切片同时验证 Rails 与 Ruby 基础运行、MySQL 连接和约束、User 与 Session、邮箱验证、后台任务、本地邮件预览、Rails Views、浏览器语言 Cookie、访问保护以及自动测试链路。

以下功能不进入第一个切片：忘记密码、登录后修改密码、设置页、新建观察、轮廓与部位、SVG、Turbo Frame 预览和 Stimulus 自动更新。

后续纵向切片及其实施顺序尚未确认，不在本文档中提前写成正式决定。

## 14. 当前仍需实施时确认或验证

- Ruby 4.0.6、Rails 8.1.x、MySQL 8.4 和所选 gems 在 Windows 原生环境中的实际兼容性。
- MySQL 8.4 并行安装前，现有 5.7 数据的备份位置、备份命令和恢复验证方式。
- 生产托管平台、生产 MySQL 方案、邮件服务供应商、发件域名、Secrets、备份和监控方案。
- 后续纵向切片的边界和先后顺序。

轮廓、颜色、花纹／特征和行动位置的最终名单仍由产品与 UI 文档管理，不因本文档中的技术可行性结论而自动获得确认。已确认的 B′ 高保真实现基线及其适配边界见 `ui-design.md`。
