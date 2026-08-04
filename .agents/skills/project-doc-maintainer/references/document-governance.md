# Document governance

## Canonical responsibilities

| File | Owns | Must not become |
| --- | --- | --- |
| `docs/project-overview.md` | Long-lived product direction, audience, technical learning direction, and stable principles | A sprint log or detailed feature backlog |
| `docs/idea-dump.md` | Unconfirmed ideas, research directions, risks, and future candidates | Approved requirements or development tasks |
| `docs/requirements.md` | Confirmed product requirements and explicitly unresolved requirement questions | Technical implementation decisions |
| `docs/mvp-scope.md` | What the current version includes, excludes, and must demonstrate | A list of every future possibility |
| `docs/current-status.md` | Current phase, confirmed state, open questions, immediate next steps, and current prohibitions | A second source of truth that silently overrides requirements or MVP scope |
| `docs/technical-decisions.md` | Confirmed important technical and architectural choices, context, rationale, and consequences | Speculation or undecided options presented as decisions |
| `AGENTS.md` | Long-lived, repository-wide agent rules, required checks, authority, review, testing, and delivery workflow | A feature requirement summary |
| `DOCUMENTS-GUIDE.md` | Document inventory, purpose, maintenance responsibility, status, and information flow | Product requirements or a stale starter-package manifest |

Treat discussions and chat as working context. Treat repository documents as the formal record only after a conclusion is confirmed and written into its owning file.

## Change inspection

When Git is available, inspect at least:

- `git status --short`
- `git diff --`
- `git diff --cached --`
- `git diff HEAD --`
- changed file names and rename/delete status

Use the last commit as the comparison baseline unless the user names another baseline. Include untracked files from status and inspect relevant ones directly because ordinary Git diffs omit them.

When Git is unavailable, state which Git evidence could not be collected. Inspect the visible file tree and file contents, but do not claim to know what changed since a commit or that no changes exist. Do not initialize Git without explicit authorization.

## Consistency checks

Check for:

- confirmed facts present only in `idea-dump.md`;
- unconfirmed ideas phrased as requirements, MVP work, current status, or agent tasks;
- requirements missing from or contradicting MVP inclusion/exclusion;
- `current-status.md` that lags confirmed requirements or declares work outside the current phase;
- important technical choices implemented in code but absent from `technical-decisions.md`;
- references to missing, renamed, or moved files;
- inventories that omit existing important documents or list nonexistent ones as current;
- two documents claiming ownership of the same fact without a clear canonical source;
- global agent rules that conflict with document governance or the current delivery workflow;
- code changes whose user-visible behavior, setup, architecture, or current status needs documentation.

Do not force every code change into project documentation. Update documents only when the change affects a fact that document owns.

## `AGENTS.md` update triggers

Consider an update only when at least one of these changes:

- the core documents agents must read;
- repository-wide development rules;
- the main technical learning direction;
- testing, review, or AI-collaboration rules;
- agent responsibilities, authority, or delivery workflow;
- a check required for every task;
- repository-wide document governance.

A normal feature-requirement change alone does not trigger an update.

If an update is needed, keep the rule concise and durable. Link to the owning document instead of copying volatile product content.

## `DOCUMENTS-GUIDE.md` update triggers

Consider an update only when at least one of these changes:

- an important document is added, deleted, moved, or renamed;
- a document's purpose, maintainer, or update timing changes;
- information flow between documents changes;
- the documentation directory structure changes;
- a formal document type or status is added;
- ChatGPT, Codex, or another tool gains or loses a documentation responsibility.

A normal requirement-content change does not trigger an update when structure and ownership remain unchanged.

Keep the guide aligned with the actual tree. Distinguish current documents from optional future documents.

## Evidence and uncertainty

For each proposed edit, cite the observed file, change, conflict, or missing path that justifies it. Preserve explicit states such as confirmed, unresolved, future candidate, and out of scope.

When evidence is incomplete:

1. Keep the existing formal decision unchanged.
2. Describe the gap precisely.
3. Put the issue under questions for the user.
4. Do not create a compromise decision or silently choose an option.

Never create product decisions merely to make documents look consistent.

## User-facing output

Make the result understandable without requiring the user to interpret raw files:

- lead with the conclusion, impact, and reason;
- explain important changes in plain language;
- quote or show only the lines needed as evidence;
- do not paste entire documents or long diffs by default;
- summarize long diffs per file and provide an inspection command or file path;
- provide the complete raw diff in the conversation only when the user explicitly asks for it.
