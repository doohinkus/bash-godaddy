# Implementation Plan: TXT Record Management

**Branch**: `002-txt-record-management` | **Date**: 2026-05-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-txt-record-management/spec.md`

## Summary

Add TXT record management to the GoDaddy DNS tool by introducing a record type toggle (CNAME/TXT) that reuses the existing CRUD pattern. The user switches types from the record management view, and all list/add/edit/delete operations work identically for TXT records.

## Technical Context

**Language/Version**: bash 3+ (macOS default)

**Primary Dependencies**: curl (required), jq (optional — grep/sed fallback)

**Storage**: N/A — temporary files under `/tmp/`, record type state stored in a variable during session

**Testing**: Manual smoke test by running through all TXT flows, plus verify CNAME flows are unaffected

**Target Platform**: macOS / Linux / Docker (bash 3+)

**Project Type**: CLI tool (TUI menu)

**Performance Goals**: No change — API calls are the bottleneck, not bash processing

**Constraints**: Must not break existing CNAME functionality. Record type toggle must be intuitive (single keypress). All existing TUI conventions (colors, prompts, navigation) must be preserved.

**Scale/Scope**: Single bash script modification — add ~100-150 lines to `godaddy-cname.sh` for TXT support

## Constitution Check

| Gate | Status | Notes |
|------|--------|-------|
| I. Simplicity First | ✅ PASS | Reuses existing CRUD pattern — no new abstractions, just parameterized record type in existing functions |
| II. Robustness & Error Handling | ✅ PASS | Existing error handling reused; TXT API errors displayed same as CNAME |
| III. Developer Experience (TUI) | ✅ PASS | Single-key toggle (`t` for type switch), clear header showing current type |
| IV. Portability | ✅ PASS | All bash 3+ compatible; no new dependencies |
| V. API Safety | ✅ PASS | All mutations confirm with user; same confirmation flow as CNAME |

## Project Structure

### Documentation (this feature)

```text
specs/002-txt-record-management/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
godaddy-cname.sh          # Modified — add record type state + TXT CRUD
lib/
├── json.sh               # Unchanged — json_record parameterized for type
├── api.sh                # Unchanged — API functions are generic
├── ui.sh                 # Unchanged
└── credentials.sh        # Unchanged
```

**Structure Decision**: All changes go into `godaddy-cname.sh`. The library files need no changes since the API/JSON helpers are already generic. The `json_record` helper already sets `"type":"CNAME"` — will need to accept a type parameter or create a `json_txt_record` variant.

## Complexity Tracking

No violations — all gates pass. This is a straightforward extension of an existing pattern with no new infrastructure.
