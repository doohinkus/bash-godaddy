<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read `specs/001-library-extraction/plan.md`
<!-- SPECKIT END -->

# Project: bash-godaddy

GoDaddy CNAME DNS record manager — a bash script (`godaddy-cname.sh`) with a TUI menu interface.

## Spec Kit (Spec-Driven Development)

- **specify CLI** v0.8.10 installed via `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v0.8.10`
- **Integration:** opencode
- **Initialized:** `specify init --here --force --integration opencode`

### Slash Commands (via `.opencode/commands/`)
- `/speckit.constitution` — project principles
- `/speckit.specify` — create specification
- `/speckit.plan` — technical implementation plan
- `/speckit.tasks` — actionable task breakdown
- `/speckit.implement` — execute implementation
- `/speckit.clarify` — clarify spec ambiguities
- `/speckit.analyze` — cross-artifact consistency
- `/speckit.checklist` — quality checklists
- `/speckit.taskstoissues` — convert tasks to GitHub issues

### Git Extensions (installed)
- `/speckit.git.feature` — start a new feature branch
- `/speckit.git.commit` — create a commit
- `/speckit.git.remote` — manage remotes
- `/speckit.git.validate` — validate branch state
- `/speckit.git.initialize` — initialize git repo

## Prerequisites (OS: macOS)
- `python3` — managed by uv (tool uses Python 3.11+)
- `uv` v0.11.3 — package manager
- `git` v2.50.1
