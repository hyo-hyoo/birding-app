---
name: project-doc-maintainer
description: Audit and maintain consistency across this repository's project documentation and project-level agent rules. Use after project documents, code, document structure, workflow rules, technical decisions, or agent responsibilities change; when checking whether workspace or committed changes are reflected in the correct documents; or when asked to review AGENTS.md, DOCUMENTS-GUIDE.md, document status, paths, ownership, overlap, and omissions. Do not implement product features or promote unconfirmed ideas into requirements or MVP scope.
---

# Project Doc Maintainer

## Required context

Read these files before judging or editing:

- `AGENTS.md`
- `DOCUMENTS-GUIDE.md`
- `docs/project-overview.md`
- `docs/idea-dump.md`
- `docs/requirements.md`
- `docs/mvp-scope.md`
- `docs/current-status.md`
- `docs/technical-decisions.md`, if it exists
- [references/document-governance.md](references/document-governance.md)

Also inspect the repository file tree, current Git status, unstaged diff, staged diff, and changes relative to `HEAD`. If Git metadata or a baseline is unavailable, report that limitation explicitly and never describe the workspace as unchanged.

## Workflow

1. State a short plan before editing.
2. Define the inspection range and change baseline.
3. Identify changed code, documents, paths, and project-level rules.
4. Map each change to the document that owns that fact.
5. Check status conflicts, broken paths, duplicated responsibility, stale inventories, and missing updates.
6. Decide separately whether `AGENTS.md` and `DOCUMENTS-GUIDE.md` meet their update triggers in the governance reference.
7. List questions when evidence is insufficient. Do not invent decisions or infer that an idea is approved.
8. Name the files that need edits and why.
9. Make only consistency and governance edits supported by evidence. Do not implement product features or change requirements or MVP scope without explicit approval.
10. Re-read affected documents, validate links and status language, then explain every change and show only the diff evidence needed to understand it.
11. If neither global file needs an update, state that explicitly and explain why each file did not meet its trigger.

## Required output

Use these sections in order:

1. 检查范围
2. 发现的变化
3. 文档一致性问题
4. `AGENTS.md` 是否需要更新及原因
5. `DOCUMENTS-GUIDE.md` 是否需要更新及原因
6. 拟修改文件
7. 修改完成后的摘要
8. 尚待用户确认的问题

Separate confirmed inconsistencies from questions and recommendations. Keep the response easy to understand: lead with conclusions and reasons, avoid pasting large file contents, and use focused diff hunks. If the complete diff is long, provide a concise per-file summary and a command or file path for inspecting it instead of dumping it into the conversation.
