## Scope Control
- Deliver the smallest change that satisfies the user's request.
- Do not add features unless explicitly asked.
- If requirements are unclear, clarify before implementation.
- Prefer simplicity over speculative or future-proof additions.

## Naming
- Apply to files, directories, classes, functions, and variables.
- Name by purpose, not implementation detail; names should survive implementation changes.
- Use responsibility-based names:
  - Classes: nouns (`UserRepository`, `SessionManager`)
  - Functions: verb + object (`createOrder`, `validateToken`)
- Prefer domain-based structure; avoid generic folders like `utils`, `helpers`.
- Avoid vague names (`data`, `info`, `thing`) except for literal storage (`data/*.json`).
- Include implementation details only if they are part of the contract (`InMemoryCache`).

## Commit Messages
- Follow Conventional Commits.
- Use a concise subject (`feat:`, `fix:`, etc.).
- Include a body describing what changed (and why if needed).

### Example
```
feat: add user authentication

  - implement JWT-based login
  - add middleware for token validation
  - update user model with password hashing
```
```
```
