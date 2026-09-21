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

## Compatibility policy

Backward compatibility is not a default requirement.

Do not add:
- compatibility flags
- aliases
- deprecated paths
- migration shims
- dual old/new behavior

When a requested change supersedes existing behavior, replace the old behavior cleanly.
Only preserve compatibility when explicitly requested by the task.

## Testing and verification

Do not write tests for reversible, low-impact changes that mirror the implementation. If you do choose to verify your work with tests, make sure that the tests are meaningful and necessary to verify implementation.

Run tests appropriate to the change and complete required checks. Once those pass, broaden or repeat testing only when new changes, failures, or unresolved concerns justify it; otherwise, continue toward completing the task.

## Commit Messages
- Follow Conventional Commits.
- Use a concise subject (`feat:`, `fix:`, etc.).
- Include a body describing what changed (and why if needed).
- Separate the subject from the body with a blank line.
- Hard-wrap body paragraphs and bullet points at 72 characters.
  Do not split words, URLs, or identifiers.

### Example
```
feat: add user authentication

  - implement JWT-based login
  - add middleware for token validation
  - update user model with password hashing
```
