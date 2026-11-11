# Lens: latency and throughput

Goal: estimate where the time goes on each request or job the spec creates or changes, and cut the largest parts first.

## 1. Build a latency budget

Walk the path from the entry point to the response and give each step a rough cost.

| Step | Typical cost |
|---|---|
| In-process work | microseconds to a few ms |
| Indexed query, same region | 1–5 ms |
| Scan of a large table | 10 ms to seconds |
| Network cache read (Redis, Memcached) | 0.5–2 ms |
| Call to another internal service | 5–50 ms |
| Third-party API | 50–500 ms |
| LLM call | 1–60 s (first token in about 0.3–3 s) |
| Object storage read or write | 20–200 ms |

Add up the steps that run one after another; for steps that run in parallel, take the slowest. Compare the total with the budget in the project profile. Without one, use: interactive API p95 under 300 ms, UI response under 100 ms as felt by the user.

## 2. Work in series that could run in parallel

Independent calls awaited one after another → run them together (`Promise.all`, `asyncio.gather`, goroutines, `CompletableFuture`). Watch the connection pool limit.

## 3. Work that does not belong on the request path

Email, notifications, file processing, imports, reports, webhooks and long AI generations → a background job. Return `202` with a status to poll, or stream progress. Use what the project already has (a job table in the database, a worker, a scheduler) before adding infrastructure.

## 4. Streaming and perceived speed

For long generations and exports: stream the result (SSE, chunked responses), show progress, render partial results. Use optimistic UI for safe actions.

## 5. Caching: climb the ladder and stop at the first step that works

1. Do not compute the same thing twice in one request (memoise per request, dataloader).
2. HTTP caching: `Cache-Control`, `ETag` with `If-None-Match` (a `304` saves bandwidth on mobile), a CDN for static or public content.
3. Precomputed data in the main database (summary tables, materialized views).
4. In-process cache with a TTL (one instance, or data that may be slightly stale per instance).
5. Shared cache (Redis, Memcached). This needs an invalidation plan, TTLs, protection against stampedes, and a defined behaviour when the cache is down.

For every cache, state what invalidates it, how stale the data may be, and what happens when many requests miss at once. No cache without an invalidation plan.

## 6. Payloads and round trips

- Size of responses (lists returning whole objects), compression.
- Chatty clients: many requests per screen → one endpoint shaped for the screen.
- Mobile networks: fewer and smaller requests.
- Images: right sizes, modern formats, lazy loading.

## 7. External dependencies

- A timeout on every call.
- Retries with backoff and jitter, only for idempotent calls.
- Circuit breaking or a fallback when a provider is down.
- The provider's rate and concurrency limits.
- Cost per call (for example AI tokens). Identical calls repeated → cache by a hash of the input.

## 8. Frontend (when the spec has UI)

Request waterfalls (fetch in parallel, prefetch), the bundle size of new dependencies, re-rendering of long lists (virtualise), heavy work on the main thread.

## 9. Throughput

Will the change multiply the load? Watch for polling by every user, fan-out writes, and scheduled jobs that loop over every tenant. Estimate requests per second and database queries per second at the stated scale. Polling → push (SSE, WebSocket), or longer intervals with `ETag`.
