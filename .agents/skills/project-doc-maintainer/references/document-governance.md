# Document governance

## Contents

- Canonical responsibilities
- Change status model
- Evidence priority and conflicts
- Change inspection
- Consistency checks
- Editing authority
- `AGENTS.md` update triggers
- `DOCUMENTS-GUIDE.md` update triggers
- Evidence and uncertainty
- Handoff example
- User-facing output

## Canonical responsibilities

| File | Owns | Must not become |
| --- | --- | --- |
| `docs/project-overview.md` | Product positioning, core users, core problem, long-term direction, and high-level product boundaries | A sprint log, UI specification, or detailed feature backlog |
| `docs/idea-dump.md` | Unconfirmed ideas, alternatives, research directions, risks, and future possibilities | Approved requirements or development tasks; move confirmed requirements to their formal owner |
| `docs/requirements.md` | Confirmed product capabilities, business rules, functional behavior, and necessary non-functional requirements | Technical implementation decisions or unconfirmed proposals |
| `docs/mvp-scope.md` | Confirmed and provisional MVP scope, exclusions, deferred candidates, boundaries, tradeoffs, and completion criteria | A list that silently promotes every requirement or prototype element into the MVP |
| `docs/ui-design.md`, if present | Page inventory and purpose, user flows, navigation, components, page states, prototype locations, and unresolved UI questions | The owner of product positioning or proof that a feature is approved |
| `docs/current-status.md` | Current phase, completed work, work in progress, next steps, blockers, and current short-term state | A second full requirements document or a source that silently overrides requirements or MVP scope |
| `docs/technical-decisions.md` | Confirmed technical choices, rationale, alternatives, constraints, and technical consequences | Speculation or undecided recommendations presented as decisions |
| `AGENTS.md` | Long-lived, repository-wide agent rules, required checks, authority, review, testing, and delivery workflow | A feature requirement summary |
| `DOCUMENTS-GUIDE.md` | Document inventory, purpose, maintenance responsibility, status, and information flow | Product requirements or a stale starter-package manifest |

Treat discussions and chat as working context. Treat repository documents as the formal record only after a conclusion is confirmed and written into its owning file.

Use one fact, one primary document. Let secondary documents reference or briefly summarize the primary fact only when their own purpose requires it; do not create independent copies that need manual synchronization.

Update `project-overview.md` only when positioning, target users, core value, long-term direction, or high-level boundaries change. A UI layout change alone does not qualify.

## Change status model

- `confirmed`: The user explicitly confirmed the item, or reliable repository evidence shows that it is a current formal decision.
- `provisional`: The item is an explicitly temporary prototype, experiment, or tentative MVP choice and is not yet a stable formal decision.
- `open-question`: Multiple options remain, discussion is active, or the user has not chosen.
- `deferred`: The item is explicitly excluded from the current phase but may be reconsidered later.
- `rejected`: The item was explicitly declined and must not be reintroduced into formal scope without a new user decision.
- `observed-only`: The item appears only in code, a prototype, a diff, or a conversation and lacks evidence of approval.

Do not infer confirmation from presentation or implementation:

- A page, control, or flow in a prototype is not automatically approved.
- Existing code does not force the requirements document to accept that behavior.
- An AI recommendation is not a user decision.
- `Can be implemented` does not mean `belongs in the MVP`.
- Explicit user confirmation outranks AI inference.
- A conflict between a handoff and a formal repository document must be surfaced, not silently overwritten.

## Evidence priority and conflicts

Use this priority as a decision aid, never as permission for lower evidence to overwrite higher evidence:

1. Explicit user confirmation in the current task.
2. Approved, current formal repository documents.
3. Committed code paired with explicit user acceptance of that implementation.
4. Current workspace code, prototypes, and Git diffs.
5. A structured change handoff.
6. An ordinary conversation summary.
7. AI suggestions and inference.

Apply these conflict rules:

- When high-priority sources conflict, ask the user rather than choosing silently.
- When a prototype conflicts with formal requirements, choose neither automatically.
- When code exceeds MVP scope, do not expand the MVP to match the code.
- When a current-task user decision clearly supersedes stale formal text, update the owning document if maintenance is authorized.
- When recency or authority cannot be established, state the limitation and request confirmation.
- Never use Git modification time as a substitute for product confirmation status.

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
- handoff items recorded in the wrong owning document;
- prototype or code observations presented as confirmed requirements;
- the same formal fact copied into multiple documents without a clear owner;
- rejected or deferred items that have reappeared as current scope;
- provisional MVP items presented without a provisional label.

Do not force every code change into project documentation. Update documents only when the change affects a fact that document owns.

## Editing authority

When the user requests maintenance and evidence is sufficient, update the owning requirements, MVP scope, UI design, current status, technical decisions, document guide, or project-level agent rules according to that file's confirmation threshold.

Do not edit when the user requests only an audit or recommendations. Even during authorized maintenance:

- do not implement features or modify business code;
- do not invent a requirement or decide an open product choice;
- do not upgrade AI suggestions, prototypes, or observed code into decisions;
- do not expand the MVP to match an implementation;
- do not create a document without a clear responsibility;
- do not duplicate facts merely for apparent completeness.

Record a `provisional` item only where the owning document supports explicit provisional state. Never phrase it as fully confirmed.

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

## Handoff example

Given this handoff:

- a low-fidelity prototype adds bottom navigation;
- it also adds a settings page and language switching;
- the user confirmed bottom navigation;
- the settings page is provisional for the MVP;
- language switching appears only in the prototype.

Classify and route it as follows:

| Change | Status | Primary document | Secondary synchronization | Action |
| --- | --- | --- | --- | --- |
| Bottom navigation | `confirmed` | `docs/ui-design.md` | Update `docs/mvp-scope.md` only if page scope changes | Record the confirmed UI decision; do not update `project-overview.md` |
| Settings page | `provisional` | `docs/ui-design.md` | Mark it provisional in `docs/mvp-scope.md` | Do not phrase it as a fully confirmed requirement |
| Language switching | `observed-only` or `open-question` | UI unresolved questions or `docs/idea-dump.md`, depending on intent | None until confirmed | Ask the user; do not add it to confirmed MVP |

The example demonstrates reasoning, not project facts. Never apply its sample decisions to the repository unless the user separately confirms them.

## User-facing output

Make the result understandable without requiring the user to interpret raw files:

- lead with the conclusion, impact, and reason;
- explain important changes in plain language;
- quote or show only the lines needed as evidence;
- do not paste entire documents or long diffs by default;
- summarize long diffs per file and provide an inspection command or file path;
- provide the complete raw diff in the conversation only when the user explicitly asks for it.
