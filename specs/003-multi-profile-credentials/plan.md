# Implementation Plan: Multi-Profile Credentials

**Branch**: `003-multi-profile-credentials` | **Date**: 2026-05-14 | **Spec**: `specs/003-multi-profile-credentials/spec.md`

**Input**: Feature specification from `specs/003-multi-profile-credentials/spec.md`

## Summary

Add multi-profile credential support to `godaddy-cname.sh` so users can switch between multiple GoDaddy API accounts. Profiles are stored as individual `.env` files in a `profiles/` directory. At startup, the script scans `profiles/` and either auto-selects (1 profile), shows a menu (2+), or falls back to existing `.env`/interactive behavior (0 profiles). The active profile name is displayed in all headers.

## Technical Context

**Language/Version**: Bash 3+ (macOS `/bin/bash` 3.2+)

**Primary Dependencies**: curl, jq (optional)

**Storage**: Filesystem — `profiles/*.env` files at project root

**Testing**: Manual (no test framework — bash script project)

**Target Platform**: macOS (bash 3+), Linux, Docker

**Project Type**: CLI (TUI interactive shell script)

**Performance Goals**: Startup profile scan < 50ms (at most 5-10 small files)

**Constraints**: bash 3+ compatible — no associative arrays, no `-1` array index. Use file-based lists. `profiles/` must be gitignored.

**Scale/Scope**: Small — single script (~340 lines), 4 library includes. This feature adds ~60 lines.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Rationale |
|------|--------|-----------|
| **I. Simplicity First** | ✅ PASS | Profile loading is a single function; selection reuses existing `select` menu pattern. No new files beyond `profiles/*.env`. |
| **II. Robustness** | ✅ PASS | Profile files validated before use. Invalid files shown as error + re-prompt. Fallback to `.env` when no profiles. |
| **III. Developer Experience (TUI)** | ✅ PASS | Profile menu uses same `select`/color scheme as domain list. Header shows profile name on every screen. |
| **IV. Portability** | ✅ PASS | `for f in profiles/*.env` and `source` are POSIX-compatible. No bash 4+ features used. |
| **V. API Safety** | ✅ PASS | Credentials from profiles never logged. AUTH header rebuilt on profile switch. |
| **VI. Backward Compatibility** | ✅ PASS | Zero profiles → existing `.env` + interactive prompt unchanged. |

## Project Structure

### Documentation (this feature)

```text
specs/003-multi-profile-credentials/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (no external API contracts for this CLI tool)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
godaddy-cname.sh          # Modified — add profile loading before credentials
lib/
├── credentials.sh        # Modified — add load_profiles(), select_profile(), apply_profile()
├── ui.sh                 # Modified — print_header optionally shows profile name
├── api.sh                # Unchanged
└── json.sh               # Unchanged
profiles/                 # NEW — gitignored, user creates *.env files here
.gitignore                # Modified — add profiles/
```

## Complexity Tracking

No constitution violations — all gates pass. Feature fits cleanly into existing architecture.
