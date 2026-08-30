# Project Instructions

Before changing project files:

1. Read `docs/current-status.md` first, then read `docs/project-overview.md`.
2. Read `DOCUMENTS-GUIDE.md`, `docs/requirements.md`, `docs/mvp-scope.md`, `docs/ui-design.md`, and `docs/technical-decisions.md` if they exist.
3. Treat `docs/idea-dump.md` as unconfirmed ideas, not as development requirements.
4. Do not expand the product scope without explicit approval.
5. Propose a short implementation plan before editing files.
6. Prefer small, reviewable changes.
7. Explain which files were changed and why.
8. Keep Ruby on Rails backend learning as the main technical focus.
9. Do not introduce Vue unless the interaction clearly requires it and explain the reason first.
10. Add or update tests for important backend behavior. The development Agent must design, write, run, and regression-check relevant tests, then report commands, test counts, failures, errors, skips, and known coverage gaps for user acceptance.
11. Do not treat AI-generated code as complete until it has been run, reviewed, and tested. Never delete, skip, or weaken tests merely to obtain a passing result.
12. Record important architectural decisions in `docs/technical-decisions.md`.
13. After formal project documents or project-level rules change, the task explicitly responsible for documentation maintenance must use `$project-doc-maintainer` to check document-system consistency. A non-Maintainer task must follow the handoff rules below instead of invoking the Skill automatically, unless the user explicitly requests documentation maintenance.
14. Make user-facing output easy to understand: lead with conclusions and impact, explain important changes in plain language, and do not paste large file contents or long diffs unless the user asks for them.
15. For UI design, prototype, or UI review tasks, use `$project-ui-designer`; within visual design work, use `$frontend-design` first to establish the visual direction, then `$mobile-app-ui-design` to check the mobile experience.
16. Treat React, Tailwind, React Native, Flutter, and SwiftUI references in external UI skills as examples only. Keep Rails Views, HTML, CSS, JavaScript, Turbo, and Stimulus as the default Web App direction unless the project explicitly approves a change.
17. Keep Project Maintainer, UI Designer, and development responsibilities separate. If a request clearly conflicts with the current task's assigned role and appears to have been sent to the wrong Codex task or window, stop before changing files, explain the mismatch, and do not execute it in that turn.
18. Write all Git commit messages in English.
19. When discussing, implementing, or handing off project changes, explicitly distinguish confirmed, provisional, open-question, deferred, rejected, AI-suggested, and observed-only content. Never promote a lower-confidence state into a formal decision without user confirmation.
20. A non-Project-Maintainer Agent must produce a change handoff only when a discussion or implementation creates a substantive change to formal project facts, rules, scope, UI decisions, project status, document structure, or technical decisions. Routine implementation that follows existing formal documents does not require an empty handoff; append exactly `本轮没有产生需要同步到正式文档的变化。` instead.
21. Before changing Rails frontend Views, ERB, CSS, JavaScript, Stimulus, I18n, or frontend tests, read `docs/frontend-implementation-guide.md` and the relevant stage in `docs/frontend-development-plan.md`.
22. Determine the current Agent role from the user's explicit task assignment and the applicable project Skill, not from the Codex task or window title. Reading formal project documents does not by itself make an Agent the Project Maintainer.
23. Unless the current task is explicitly assigned as Project Maintainer or the user explicitly requests formal documentation maintenance, do not invoke `$project-doc-maintainer` and do not independently edit formal project documents merely to record decisions produced by discussion or implementation. Continue the authorized UI, development, review, or other role and hand the facts to Project Maintainer. This does not prevent required reading of formal documents or updates to execution records explicitly owned by the current role.
24. A non-Project-Maintainer change handoff must use these headings: `本轮已确认的决定`, `当前暂定的方案`, `仍未确认的问题`, `已延后或否决的内容`, `原型、代码或设计中已经出现，但尚未确认的变化`, and `建议 Project Maintainer 检查的内容`. Describe facts and confirmation states only; label AI suggestions explicitly, do not decide the final owning files, and do not promote suggestions or observed-only content into user decisions.
25. Before changing Rails backend domain boundaries, Models, database design, Migrations, persistence, authentication, authorization, Mailers, Jobs, or backend tests, read `docs/backend-development-plan.md` and `docs/database-design.md`.
26. From backend development stage 2 onward, the development Agent may autonomously make routine engineering decisions that follow formal requirements, existing technical decisions, Rails conventions, and current project constraints when those decisions are low-cost and reasonably reversible. A short plan is still required, but routine implementation details do not require item-by-item user approval.
27. Escalate to the user before proceeding when a decision changes product behavior or MVP scope, changes an approved primary technical direction, affects security, privacy, authentication, or unrecoverable data risk, introduces a major dependency or infrastructure component, has substantial migration cost, or exposes a formal-document conflict that cannot be resolved from existing authority.
28. Keep each escalation to the smallest set of genuinely blocking human decisions, normally no more than 1–3 questions. State the recommended option and why development is blocked; do not default to large A/B/C decision lists.
29. Prefer Minitest, System Test, database constraints, RuboCop, Brakeman, and other reproducible checks for engineering correctness. The user primarily confirms product and risk boundaries, accepts user-visible behavior, and learns the important Rails flow rather than approving every implementation detail.
30. At important backend vertical milestones, explain the core request path in plain language: user action → Route → Controller → Model or necessary flow object → Database → View or Redirect, including the main validation and authorization points.
