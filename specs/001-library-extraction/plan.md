# Implementation Plan: Library Extraction Refactor

**Branch**: `001-library-extraction` | **Date**: 2026-05-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-library-extraction/spec.md`

## Summary

Extract helper functions from the monolithic 498-line `godaddy-cname.sh` into standalone library files under `lib/`. JSON helpers, API communication, TUI utilities, and credential management each become a separate sourced file with single responsibility. The main script remains as the orchestration entry point. No behavioral changes — the user experience is identical before and after.

## Technical Context

**Language/Version**: bash 3+ (macOS default)

**Primary Dependencies**: curl (required), jq (optional — grep/sed fallback)

**Storage**: N/A — temporary files under `/tmp/`

**Testing**: Manual smoke test by running the script through all menu flows; also test each `lib/*.sh` by sourcing individually in a bash shell

**Target Platform**: macOS / Linux / Docker (bash 3+)

**Project Type**: CLI tool (TUI menu)

**Performance Goals**: No change from current — startup time may increase marginally due to additional source operations (<100ms)

**Constraints**: Must maintain backward compatibility with bash 3+, must not introduce bash 4+ only features (no associative arrays, no `**` globs), must preserve all function names so orchestration code needs zero changes

**Scale/Scope**: Single bash script → 5 files (1 main + 4 libraries)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| I. Simplicity First | ✅ PASS | Single-file remains for orchestration; extraction is justified by separation of concerns |
| II. Robustness & Error Handling | ✅ PASS | All existing error handling preserved; missing library files get clear error messages |
| III. Developer Experience (TUI) | ✅ PASS | UI helpers extracted cleanly; no behavioral changes to prompts, colors, or navigation |
| IV. Portability | ✅ PASS | All libraries use bash 3+ compatible syntax; grep/sed fallback preserved for jq-less environments |
| V. API Safety | ✅ PASS | Credential handling extracted but unchanged; `.env` loading stays in main script |

## Project Structure

### Documentation (this feature)

```text
specs/001-library-extraction/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (interface contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
godaddy-cname.sh          # Main entry point — sources lib/*.sh and orchestrates TUI flow
lib/
├── json.sh               # JSON helpers: json_fields, json_field_at, json_record,
│                         #   json_filter_out, json_count
├── api.sh                # API helpers: api_get, api_patch, api_put
├── ui.sh                 # TUI helpers: colors, clear_screen, print_header,
│                         #   pause, confirm
└── credentials.sh        # Credential helpers: check_credentials
```

**Structure Decision**: Flat `lib/` directory with one file per responsibility domain. The main script at the repo root sources all four. This matches the "Single project (DEFAULT)" pattern from the template since this is a single-script bash tool.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — all gates pass. The four-library split is justified by the constitution's own principles (Simplicity First says extract only when justified, and separation of concerns for maintainability qualifies).
