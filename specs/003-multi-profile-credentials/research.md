# Research: Multi-Profile Credentials

## Summary

No unresolved clarifications — the spec is complete and unambiguous. This document records technical decisions made during planning.

## Decisions

### Decision 1: Profile discovery via filesystem glob

- **Decision**: Use `for f in "$SCRIPT_DIR/profiles/"*.env; do ... done` to discover profiles
- **Rationale**: Simple, POSIX-compatible, works in bash 3+. No config file parsing needed.
- **Alternatives considered**:
  - JSON config file — too complex for this use case
  - Environment variables (`GODADDY_PROFILE_1_KEY`, etc.) — awkward and error-prone
  - Single `profiles/config` file — requires custom parser, less intuitive than individual files

### Decision 2: Profile source via `set -a; source; set +a`

- **Decision**: Source profile files using the same `set -a`/`source`/`set +a` pattern used for `.env`
- **Rationale**: Reuses proven pattern, handles export automatically. Works identically to existing `.env` loading.
- **Alternatives considered**:
  - `read` line-by-line — fragile, doesn't handle quoted values
  - `eval` — security risk
  - `grep/sed` extraction — fragile with edge cases

### Decision 3: Profile validation via subshell sourcing

- **Decision**: Validate by sourcing profile in a subshell and checking `GODADDY_API_KEY` and `GODADDY_API_SECRET` are non-empty
- **Rationale**: Catches syntax errors (subshell exit code) and missing fields (empty variable check) without polluting the main shell's state.
- **Alternatives considered**:
  - `source` directly and check — could leave partial state on error

### Decision 4: Profile name display

- **Decision**: Derive display name from filename (strip `.env`, uppercase first letter only in header)
- **Rationale**: Simple, predictable. Display as `[production]` in header using the raw stem of the filename.
- **Alternatives considered**:
  - Allow display name inside file — over-engineered for this use case
