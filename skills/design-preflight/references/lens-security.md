# Lens: security and data exposure

Scope: the design-level risks this spec adds or changes. This is not a full security audit.

1. **Authorisation on the server** for every new or changed endpoint, job and file URL: role, ownership of the resource, and tenant. Check IDs sent by the client against the caller's tenant (IDOR).
2. **Data exposure:** responses are built from allow-lists (DTOs, serializers), not whole models. Sensitive fields (answers, internal notes, tokens, personal data) never reach roles that must not see them. Logs and analytics carry no personal data or secrets.
3. **Data sent to third parties** (AI, analytics, email): only what is needed, and no personal data unless the project allows it.
4. **Input:** validated at the server boundary with a schema, with size limits. Uploads are checked for type and size. CSV, XML and archive files are parsed safely.
5. **Injection:** SQL built from strings, template injection, and prompt injection when user content reaches an LLM that can call tools or affect other users.
6. **Abuse:** rate limits on expensive endpoints (AI, exports, email), enumeration of IDs or accounts, unbounded uploads.
7. **Secrets and configuration:** no secrets in code, and none in variables that are built into the client bundle.
8. **Audit trail** for sensitive actions, if the project keeps one.

Evidence: the handler and its guard or middleware, the serializer, and the test that proves a refused case.
