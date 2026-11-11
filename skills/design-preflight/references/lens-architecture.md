# Lens: architecture and design

## 1. Fit with the existing system

- Find the closest existing feature. Does the natural way to build this spec follow its pattern?
- Flag a second way of doing the same thing: a second HTTP client, another job mechanism, another validation library, another error format.
- If the existing pattern is the problem, say so and propose a path to move away from it, not a one-off exception.

## 2. Boundaries and ownership

- Which module owns each piece of data the spec touches? Writes from outside the owner go through its public service or API.
- Reaching into another module's internals, shared mutable state, circular imports.
- Business logic in routes, controllers or UI components → move it to the service layer.

## 3. Domain model

- A status field with implicit transitions → an explicit state machine: allowed transitions, who may trigger each, a timestamp per transition.
- Concepts the spec names that the code lacks, or names differently → align the words.
- Modules coupled through a shared table.

## 4. Configuration and hard-coded values

- Values that differ by environment or change over time (URLs, limits, durations, model IDs, feature switches) → configuration.
- Behaviour that differs by tenant → tenant settings.
- Numbers with a meaning → named constants.

## 5. External services

- One interface per provider (AI, email, storage, payments), with a fake for tests. Feature code does not call the SDK directly.
- Timeouts and error mapping at the boundary, so provider errors never reach users raw.

## 6. APIs and contracts

- Consistent with existing endpoints: naming, errors, pagination, dates.
- Backward compatible for existing clients. Mobile apps cannot be forced to update.
- Versioning if a change breaks clients.
- Typed errors with a code and a safe message.

## 7. Background work and side effects

- Delivery is at least once, so handlers must be idempotent.
- "Write to the database and send something" → the outbox pattern.
- Retries, a failed state that operators can see, and a way to replay.

## 8. Extensibility against YAGNI

Flag both:

- hard-coding something that the roadmap (linked tickets, the epic) clearly needs to vary
- an abstraction with one implementation and no planned second one

## 9. The simplest thing

Is there a much simpler design that still meets every acceptance criterion? Propose it and say what it gives up.
