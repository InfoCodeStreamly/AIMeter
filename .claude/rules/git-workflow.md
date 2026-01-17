# Git Workflow Rules

## Commit & Push — ONE COMMAND

**ALWAYS** commit and push to `stage` and `main` in a single command:

```bash
git add -A && git commit -m "type: message

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>" && git push origin stage && git checkout main && git merge stage --no-edit && git push origin main && git checkout stage
```

**NEVER** run separate commands for:
- git add
- git commit
- git push stage
- git checkout main
- git merge
- git push main

Everything in ONE command using `&&`.

## Commit Message Format

```
type: short description

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

Types:
- `feat:` — new feature
- `fix:` — bug fix
- `refactor:` — code refactoring
- `docs:` — documentation
- `chore:` — technical changes

## Branch Strategy

- `stage` — development branch (commit here first)
- `main` — production branch (merge from stage)
- Always work on `stage`, then merge to `main`
