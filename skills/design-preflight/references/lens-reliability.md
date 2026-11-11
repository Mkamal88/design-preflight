# Lens: reliability, testing and operations

1. **Acceptance criteria → tests.** For each criterion, name the test that will prove it (unit, integration or end-to-end) and list the missing ones. Business rules (dates, time zones, limits, permissions) need unit tests at their boundaries.
2. **Failure modes.** What happens when each dependency is slow, down, or returns bad data? When an operation with several steps fails halfway? When the user retries or double-clicks?
3. **Idempotency and retries.** Can every retried operation run twice safely?
4. **Migrations and rollout.** Rollback steps, a feature flag for risky changes, a backfill plan, and old code running against the new schema during the deploy.
5. **Observability.** Logs with IDs and no personal data; metrics for the new path (latency, errors, queue depth); alerts when a background job stops. How will the team know it is broken in production?
6. **Time and locale.** Stored in UTC and converted to the user's or tenant's time zone; daylight-saving edges; dates near midnight.
7. **Limits.** Maximum sizes, item counts and timeouts, and what the user sees when one is exceeded.
8. **Data over time.** Clean-up jobs, retention, orphaned rows.
