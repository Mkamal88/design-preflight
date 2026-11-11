# Constraint-challenging proposals

Some of the best design improvements need the team to change one of its rules (from `AGENTS.md`, `CLAUDE.md`, decision records or the project profile): adding Redis, a message queue, a search engine, a new service, a different database, a CDN or read replicas.

This skill raises them, in a separate section and in a form that makes the decision quick and safe. It never hides them, and it never acts on them alone.

## When to raise one

All of these must be true:

1. There is a specific problem in this spec at the stated scale (or the scale expected within about a year). "It might be useful one day" is not enough.
2. There is evidence: a measurement, code you read, or a latency budget that clearly fails.
3. You worked out the best within-rules alternative, and it is clearly worse. Say by how much.
4. The proposal is not on the project's rejected list, unless there is new evidence. In that case, say what changed.

How many to raise: up to 3 by default; none with `--strict`; more with `--open`, where speculative ones are allowed if labelled `Speculative`.

## The ladder before new infrastructure

Check whether a lower step solves the problem first:

| Need | Ladder (lowest first) |
|---|---|
| Cache | HTTP caching → precomputed tables or materialized views → in-process TTL cache → Redis or Memcached |
| Queue | Job table in the database with a worker (`SELECT ... FOR UPDATE SKIP LOCKED`), or `LISTEN/NOTIFY` → managed queue (SQS, Cloud Tasks, Pub/Sub) → broker (RabbitMQ, Kafka) |
| Search | Indexes → trigram or full-text search in the database → a search engine |
| Analytics | Read replica or materialized views → a data warehouse |
| Scale | Query and index fixes → a bigger instance → read replicas → partitioning or sharding |
| New service | A module with clear boundaries inside the existing app → a separate service |

## Decision record (use this in the report)

```text
### P-1: <proposal title>
Rule affected: <file and rule, quoted briefly>
Problem: <what fails, where (path:line), at what scale>
Evidence: <measurement or calculation> (Measured / Observed / Estimated)
Proposal: <what to add or change, and its scope>
Expected gain: <metric before → after, with confidence>
Costs: <build effort, running cost, operations (deploys, monitoring, backups, on-call),
        new failure modes, security surface, skills the team needs>
Within-rules alternative: <best option without changing the rule> → gain <...>, effort <...>
Reversibility: <how hard it is to undo>
Decision needed from: <the role the rules name, for example the tech lead>
Recommendation: <adopt now | adopt when <trigger> | do not adopt>
```

"Adopt when" triggers are often the most useful answer. For example: "Add Redis when p95 of `GET /lessons` stays above 300 ms for a week, or traffic passes 500 requests per second."

## Never

- Build a constraint-challenging proposal, or write code that assumes it, without the user's explicit yes and the decision the project's rules require.
- Hide a rule change inside a within-rules finding.
