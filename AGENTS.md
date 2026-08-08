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
10. Add or update tests for important backend behavior.
11. Do not treat AI-generated code as complete until it has been run, reviewed, and tested.
12. Record important architectural decisions in `docs/technical-decisions.md`.
13. After project documents or project-level rules change, use `$project-doc-maintainer` to check document-system consistency.
14. Make user-facing output easy to understand: lead with conclusions and impact, explain important changes in plain language, and do not paste large file contents or long diffs unless the user asks for them.
15. For UI design, prototype, or UI review tasks, use `$project-ui-designer`; within visual design work, use `$frontend-design` first to establish the visual direction, then `$mobile-app-ui-design` to check the mobile experience.
16. Treat React, Tailwind, React Native, Flutter, and SwiftUI references in external UI skills as examples only. Keep Rails Views, HTML, CSS, JavaScript, Turbo, and Stimulus as the default Web App direction unless the project explicitly approves a change.
17. Keep Project Maintainer, UI Designer, and development responsibilities separate. If a request clearly conflicts with the current task's assigned role and appears to have been sent to the wrong Codex task or window, stop before changing files, explain the mismatch, and do not execute it in that turn.
