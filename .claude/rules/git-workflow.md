# Git Workflow Rules

## Commit & Push — ONE COMMAND

**ЗАВЖДИ** комітити та пушити в `stage` і `main` однією командою:

```bash
git add -A && git commit -m "type: message

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>" && git push origin stage && git checkout main && git merge stage --no-edit && git push origin main && git checkout stage
```

**НІКОЛИ** не робити окремі команди для:
- git add
- git commit
- git push stage
- git checkout main
- git merge
- git push main

Все в ОДНУ команду через `&&`.

## Commit Message Format

```
type: short description

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

Types:
- `feat:` — нова функціональність
- `fix:` — виправлення багу
- `refactor:` — рефакторинг
- `docs:` — документація
- `chore:` — технічні зміни
