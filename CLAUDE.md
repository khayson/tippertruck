# CLAUDE.md — tippertruck (monorepo root)

Monorepo for the Tipper Truck sand ordering app. Two deployables, one repository.

```
api/      Laravel 13 REST API + Filament admin panel   → see api/CLAUDE.md
mobile/   Flutter client                                → see mobile/CLAUDE.md
docs/     BUILD_SPEC.md (architecture) · API_CONTRACT.md (the contract)
```

## Read before writing any code

1. `docs/BUILD_SPEC.md` — architecture, schema decisions, milestone plan, acceptance criteria.
2. `docs/API_CONTRACT.md` — the frozen contract between `api/` and `mobile/`.
3. The `CLAUDE.md` inside whichever directory you are working in.

## Rules that apply across both sides

- **The API contract is frozen.** If implementation shows something in `docs/API_CONTRACT.md` is wrong or missing, stop and raise it — do not change one side to match your implementation. A contract change is a review item and must land as a single commit touching `docs/`, `api/` and `mobile/` together. That atomicity is the reason this is a monorepo.
- **Work one milestone at a time** (BUILD_SPEC §6). Stop at each gate and report: what was built, tests passing, what the spec got wrong. Do not roll into the next milestone.
- **This is a public repository.** No real names, phone numbers, MoMo numbers or addresses in seeders, tests, fixtures or screenshots — generate fakes. No `.env`, no credentials, no API keys, ever. Not in a commit you plan to amend either; the object stays in history.
- **Commits are scoped to one side** where possible: `feat(api): ...`, `fix(mobile): ...`, `docs: ...`, `chore: ...`. Contract changes use `feat(api,mobile): ...`.
- Never commit directly to `main`. Branch as `m3/orders-endpoint`, open a PR, let CI pass.

## Commands

Development happens on **Windows / PowerShell**. Use `tasks.ps1`; the `Makefile`
is the equivalent for macOS and Linux.

```powershell
.\tasks.ps1 setup     # install both sides
.\tasks.ps1 api       # serve the API on 0.0.0.0:8000
.\tasks.ps1 mobile    # run the Flutter app
.\tasks.ps1 test      # pest + flutter test
.\tasks.ps1 lint      # pint + dart format + flutter analyze
.\tasks.ps1 fresh     # migrate:fresh --seed (destroys local data)
```

Windows notes for anything you script:
- Paths in commands use `\`; paths in code, configs and CI stay `/`.
- `.gitattributes` forces LF in the repository — do not add CRLF line endings.
- Composer version constraints must be single-quoted (`'laravel/laravel:^13.0'`)
  or `cmd.exe` eats the caret.
- Flutter targets Android first here; iOS is unbuildable on this machine and
  that is expected.
