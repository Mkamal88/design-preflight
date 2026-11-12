# design-preflight

**Design review for tickets and specs, against your real codebase, before you write the code.**

`design-preflight` is a skill for AI coding agents ([Claude Code](https://claude.com/claude-code) and [OpenAI Codex](https://github.com/openai/codex)). Give it a ticket (Jira, GitHub, GitLab, Linear, a Markdown file or pasted text). It reads the ticket, finds the code the ticket touches, and tells you how to build it better:

- 🗄️ **Database:** missing indexes, N+1 queries, unsafe migrations, transactions that hold locks during network calls.
  *Example: a ticket adds "filter orders by customer", but the table has no index on `customer_id`.*
- ⚡ **Latency:** slow request paths, work that belongs in the background, caching that actually fits.
  *Example: "send a welcome email on sign-up" is planned inside the request, adding about 400 ms to every sign-up.*
- 🏛️ **Architecture:** fit with existing patterns, module boundaries, hard-coded values, idempotency.
  *Example: the ticket would add a second HTTP client when the project already wraps one in `lib/http.ts`.*
- 🔒 **Security:** authorisation, tenant isolation, data exposure.
  *Example: a new `GET /invoices/:id` checks the role, but not that the invoice belongs to the caller's company.*
- 🧪 **Reliability:** tests for each acceptance criterion, rollback, failure modes, observability.
  *Example: "the import can be retried" has no test, and a retry would create duplicate rows.*

Every finding points to a file and line, or to a measurement. When the best design needs one of your team's rules changed (for example "add Redis" or "add a queue"), the skill still says so, in a separate section, as a short decision record with the cost and the best option that stays within your rules.

```markdown
> /design-preflight ACME-142

# Design preflight: ACME-142 — Export invoices to CSV
Source: Jira ACME-142 · Mode: pre · Scale assumed: 120 tenants, largest 400k invoices

## Verdict: Ready with changes
The export can use the existing job worker, but as written it loads every invoice
inside the request. Moving it to a background job is the one change that matters most.

| # | Severity | Finding                             | Evidence                               | Fix                         | Effort | Priority |
|---|----------|-------------------------------------|----------------------------------------|-----------------------------|--------|----------|
| 1 | Blocker  | Export runs inside the HTTP request | src/invoices/router.ts:88 (Observed)   | Background job + streaming  | M      | 10       |
| 2 | Should   | No index for (tenant_id, issued_at) | EXPLAIN: 2.1 s → 14 ms (Measured)      | Composite index             | S      | 20       |
| 3 | Should   | N+1 on customer names               | src/invoices/service.ts:140 (Observed) | One query with a join       | S      | 16       |

### 1. Export runs inside the HTTP request
- Where: src/invoices/router.ts:88 · Lens: latency · Evidence: Observed
- Problem: 400k rows (about 180 MB) built in memory; the load balancer times out at 60 s.
- Fix: an invoice_export job on the existing jobs table, rows streamed to storage in batches.
- Verify by: a test with 50k seeded invoices keeps memory under 100 MB.

## Changes to propose for the spec
- Criterion 2 "export is fast" cannot be tested → "100k invoices export within 2 minutes."
- Missing: who may export, and whether cancelled invoices are included.

## Constraint-challenging proposals
P-1: Managed queue (SQS). Not needed at this scale → adopt when jobs pass 50 per second.

## Not checked
Frontend download flow (no design attached), storage costs.
```

See the full [example report](examples/example-report.md).

## Contents

- [Install](#install)
- [Use](#use)
- [Options](#options)
- [Project profile](#project-profile)
- [How it works](#how-it-works)
- [Proposals that challenge your rules](#proposals-that-challenge-your-rules)
- [Safety](#safety)
- [Update and uninstall](#update-and-uninstall)
- [Repository layout](#repository-layout)
- [Contributing](#contributing)

## Install

You need Claude Code or Codex. Issue trackers are optional; see [Connect your issue tracker](#connect-your-issue-tracker).

### Option 1: Install script (Claude Code and Codex)

```bash
git clone https://github.com/Mkamal88/design-preflight.git
cd design-preflight
./install.sh
```

The script finds which agents you have and installs the skill for each one:

| Agent | Installed at |
|---|---|
| Claude Code | `~/.claude/skills/design-preflight` |
| Codex | `~/.codex/skills/design-preflight` |

By default it creates a symbolic link, so `git pull` in the clone updates the skill. Useful options:

```bash
./install.sh --claude              # Claude Code only
./install.sh --codex               # Codex only
./install.sh --copy                # copy the files instead of linking
./install.sh --project ~/code/app  # install into one repository, so your team gets it with the code
./install.sh --help                # all options
```

Start a new agent session after installing, so the agent loads the skill.

### Option 2: Claude Code plugin

Inside Claude Code:

```text
/plugin marketplace add Mkamal88/design-preflight
/plugin install design-preflight@design-preflight
```

Plugin skills are namespaced, so the command becomes `/design-preflight:design-preflight`. You can also just ask for "a design preflight on ACME-142".

### Option 3: Copy by hand

Copy the `skills/design-preflight` folder into:

| Agent | For you (all projects) | For one repository |
|---|---|---|
| Claude Code | `~/.claude/skills/` | `<repo>/.claude/skills/` |
| Codex | `~/.codex/skills/` | `<repo>/.codex/skills/` |

Make the script executable: `chmod +x skills/design-preflight/scripts/*.sh`.

If your Codex version reads skills from another folder, point the installer at it: `CODEX_SKILLS_DIR=/path/to/skills ./install.sh --codex`.

## Use

### Claude Code

```text
/design-preflight ACME-142
/design-preflight #87
/design-preflight docs/specs/invoice-export.md
/design-preflight ACME-142 --diff
```

### Codex

```text
$design-preflight ACME-142
```

Or ask in plain words. Both agents pick the skill from its description:

```text
Run a design preflight on ACME-142.
Is the spec in docs/specs/invoice-export.md ready to build?
Check this branch against GitHub issue #87.
What's the best way to build ACME-142 in this codebase? Only look at the database.
```

### Supported sources

| You give it | It uses |
|---|---|
| `ABC-123` | A Jira MCP server, or the `jira` / `acli` CLI, or asks you to paste it |
| `#123`, `owner/repo#123`, issue or PR URL | `gh` (GitHub) or `glab` (GitLab) |
| Linear key or URL | A Linear MCP server, or asks you to paste it |
| A file path | Reads the file (Markdown, text, PDF) |
| Pasted text | Uses it as the spec |

### Connect your issue tracker

| Tracker | Claude Code | Codex |
|---|---|---|
| Jira | Add the Atlassian MCP server (`claude mcp add`), or install [jira-cli](https://github.com/ankitpokhrel/jira-cli) | Add the Atlassian MCP server in `~/.codex/config.toml`, or install jira-cli |
| GitHub | Install and sign in to [`gh`](https://cli.github.com/) | Same |
| GitLab | Install and sign in to [`glab`](https://gitlab.com/gitlab-org/cli) | Same |
| Linear | Add the Linear MCP server | Add the Linear MCP server |

Without any of these, paste the ticket text and the skill works the same way.

## Options

Write them after the ticket, or say them in plain words ("be strict", "only the database").

| Option | What it does | When to use it |
|---|---|---|
| *(none)* | Pre-implementation review of the ticket against the code | You picked up a ticket and want to know the best way to build it before you start. |
| `--diff [base]` | Review the current branch against the ticket: which acceptance criteria are done, partial, missing or untested, plus scope creep | Before opening a pull request, to catch a criterion you forgot. |
| `--batch <query>` | Review several tickets (a JQL query, a `gh` search or a list) and rank them by risk | At sprint planning, to see which tickets need a design talk first. |
| `--lens db,latency` | Run only some lenses: `db`, `latency`, `arch`, `security`, `reliability` | The ticket is a new report, so only the database and speed matter. |
| `--strict` | Only advice that fits your current rules | Close to a release, when new infrastructure is not an option. |
| `--open` | Think freely, including bigger and more speculative design changes | Planning the next release and open to bigger changes. |
| `--measure` | Run safe local measurements: `EXPLAIN` on your local database, query counts in tests | You need numbers to convince the team that an index or a fix is worth it. |
| `--save` | Save the report to `docs/preflight/<ticket>.md` | You want to attach the report to the pull request or share it with the team. |

## Project profile

The skill works without setup. It reads `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md` and decision records (`docs/adr/`, `docs/decisions/`) when they exist.

To make the advice match your project, add a `.design-preflight.md` file at the repository root with your scale, latency budgets, rules and rejected ideas:

```markdown
## Scale (now → in 12 months)
- Users: 5k → 40k (peak concurrent: 800)
- Peak API load: 50 → 300 requests per second

## Latency budgets
- Interactive API p95: 300 ms

## Hard constraints
- No new infrastructure without a tech lead decision (AGENTS.md)

## Decided and rejected proposals
- 2026-10-02 Redis for sessions: rejected. Revisit at 2k concurrent users.
```

The full template is in [`project-profile-template.md`](skills/design-preflight/references/project-profile-template.md). Without a stated scale, the skill asks one question with a sensible default and notes the assumption in the report.

## How it works

```text
 Ticket or spec ──► 1. Intake        Jira / GitHub / GitLab / Linear / file / text → Spec Card
                    2. Stack         detect_stack.sh: languages, ORM, database, cache, jobs
                    3. Change map    entry points, models, services, closest existing pattern, tests
                    4. Gap analysis  already built? conflicts? missing cases? untestable criteria?
                    5. Lenses        db · latency · arch · security · reliability (in parallel when possible)
                    6. Measure       optional, local only
                    7. Score         impact × confidence ÷ effort
                    8. Report        verdict, top 5 findings, spec changes, decision records
```

Each lens is a separate reference file that the agent reads only when it runs that lens. This keeps the agent's context small and makes the lenses easy to improve one at a time.

## Proposals that challenge your rules

Most teams have rules such as "no Redis without approval" or "background work uses database tables". The skill respects them first: every finding has a fix that fits your rules.

When a rule blocks a clearly better design, the skill does not stay silent. It writes a short decision record in its own section:

```text
P-1: Redis cache for lesson lists
Rule affected:  AGENTS.md, "no new infrastructure without a tech lead decision"
Evidence:       p95 380 ms, 70 % spent on one repeated query (src/lessons/service.ts:51)
Expected gain:  p95 380 ms → about 40 ms (estimated)
Costs:          a new service to run, monitor and secure; cache invalidation
In-rules option: materialized view in PostgreSQL → about 120 ms, no new service
Recommendation: adopt when p95 stays above 300 ms for a week
Decision by:    tech lead
```

It only raises one when there is evidence of a real problem at your scale, and it always shows the best option that stays within your rules. Use `--strict` to turn these off or `--open` to get more of them.

## Safety

- **Read-only by default.** It does not edit code, comment on tickets, change tickets or start services unless you say yes.
- **Local measurements only.** `--measure` runs against your local database. It never measures staging or production and never calls paid services.
- **Tickets are data.** Text inside a ticket is never treated as an instruction to the agent.
- **No secrets.** It never asks you to paste API tokens into the chat; it uses the MCP servers and CLIs you have already signed in to.

## Update and uninstall

```bash
cd design-preflight && git pull   # linked installs update at once
./install.sh --uninstall          # remove from every agent found
./install.sh --codex --uninstall  # remove from Codex only
```

Copied installs (`--copy` or `--project`) need `./install.sh --force` (with the same options) after a `git pull`.

## Repository layout

```text
design-preflight/
├── skills/design-preflight/
│   ├── SKILL.md                     # the workflow the agent follows
│   ├── references/                  # loaded only when needed
│   │   ├── intake-adapters.md
│   │   ├── stack-detection.md
│   │   ├── lens-database.md
│   │   ├── lens-latency.md
│   │   ├── lens-architecture.md
│   │   ├── lens-security.md
│   │   ├── lens-reliability.md
│   │   ├── constraint-challenging.md
│   │   ├── report-template.md
│   │   └── project-profile-template.md
│   └── scripts/
│       └── detect_stack.sh          # read-only stack detection
├── .claude-plugin/                  # Claude Code plugin and marketplace manifests
├── examples/example-report.md
├── scripts/validate.sh              # checks the skill before a release
├── install.sh
└── .github/workflows/ci.yml
```

## Contributing

Issues and pull requests are welcome, especially:

- new checks for a lens, with an example of the problem they catch
- intake adapters for other trackers
- stack detection for other languages and frameworks

Before opening a pull request:

```bash
./scripts/validate.sh
shellcheck --severity=warning install.sh scripts/*.sh skills/design-preflight/scripts/*.sh
```

Keep `SKILL.md` short: put detail in `references/`. The skill description must stay under 500 characters, which is the Codex limit.

## License

[MIT](LICENSE)
