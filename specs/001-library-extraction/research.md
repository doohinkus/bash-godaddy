# Research: Library Extraction Refactor

## No Technical Unknowns

This refactor has zero unknowns — the existing codebase is well-understood, and bash `source` patterns are decades-old established practice.

### Approach

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| `source` all libs at top of main script | Simplest approach, zero overhead, works in all bash 3+ versions | `eval $(cat lib/foo.sh)` — fragile, harder to debug |
| Flat `lib/` with one file per concern | Matches single-file origin, easy to navigate, no nesting overhead | Subdirectory per domain — over-engineering for 4 files |
| Preserve all function names verbatim | Orchestration code needs zero changes; diff is purely structural | Renaming — introduces risk of regressions for no benefit |
| All paths relative to `SCRIPT_DIR` | Portable across working directories, matches current pattern | `$PATH`-based lookup — would break Docker and non-standard setups |

### Bash Sourcing Best Practices

- Use `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` for path resolution
- Source with: `source "$SCRIPT_DIR/lib/json.sh"`
- Use `set -euo pipefail` in main script; libraries should not re-set it (but should tolerate it)
- Guard against double-sourcing with `[[ -z "$_LIB_NAME_LOADED" ]] && _LIB_NAME_LOADED=1 || return` (optional — not needed for this refactor since each lib is sourced once)

### Files to Extract

| Source Lines | Target File | Functions |
|---|---|---|
| 37-51 | `lib/api.sh` | `api_get`, `api_patch`, `api_put` |
| 57-114 | `lib/json.sh` | `json_fields`, `json_field_at`, `json_record`, `json_filter_out`, `json_count` |
| 120-169 | `lib/ui.sh` | `clear_screen`, `print_header`, `pause`, `confirm` + color variables |
| 175-194 | `lib/credentials.sh` | `check_credentials` + `AUTH` variable init |
