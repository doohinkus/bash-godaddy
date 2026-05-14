# Tasks: Library Extraction Refactor

**Input**: Design documents from `specs/001-library-extraction/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Create directory structure and foundation for extraction

- [X] T001 Create `lib/` directory at project root
- [X] T002 Create stub library files in `lib/` (`lib/json.sh`, `lib/api.sh`, `lib/ui.sh`, `lib/credentials.sh`) with explanatory header comments

**Checkpoint**: `lib/` directory exists with all four stub files

---

## Phase 2: User Story 2 - Library Files Sourced from `lib/` (Priority: P1)

**Goal**: Extract helper functions into standalone library files under `lib/` and source them from the main script.

**Independent Test**: Run `./godaddy-cname.sh` and verify all menu flows work exactly as before.

- [X] T003 [P] [US2] Extract JSON helper functions (`json_fields`, `json_field_at`, `json_record`, `json_filter_out`, `json_count`) into `lib/json.sh`
- [X] T004 [P] [US2] Extract API communication functions (`api_get`, `api_patch`, `api_put`) into `lib/api.sh`
- [X] T005 [P] [US2] Extract TUI helper functions and color variables (`clear_screen`, `print_header`, `pause`, `confirm`, `$R $G $Y $B $P $C $GR $BO $NC`) into `lib/ui.sh`
- [X] T006 [P] [US2] Extract credential management (`check_credentials`) into `lib/credentials.sh`
- [X] T007 [US2] Add `source` statements at the top of `godaddy-cname.sh` (after `SCRIPT_DIR`) to load all four library files using `$SCRIPT_DIR/lib/` paths
- [X] T008 [US2] Update the `.env` loading section in `godaddy-cname.sh` to load `.env` before sourcing libraries (libraries may need env vars)
- [X] T009 [US2] Remove all extracted function definitions from `godaddy-cname.sh` (they now live in the library files)
- [X] T010 [US2] Keep `cleanup`, `trap`, `SCRIPT_DIR`, and `.env` loading in `godaddy-cname.sh`

**Checkpoint**: At this point, all helper functions have been extracted to library files and `godaddy-cname.sh` sources them correctly.

---

## Phase 3: User Story 3 - Each Library Individually Testable (Priority: P2)

**Goal**: Each library file can be sourced independently without errors or side effects.

**Independent Test**: Run `source lib/json.sh && echo OK` for each library and verify no errors.

- [X] T011 [P] [US3] Ensure `lib/json.sh` has no side effects at load time — wrap any top-level code in functions
- [X] T012 [P] [US3] Ensure `lib/api.sh` has no side effects at load time — it should only define functions, not make API calls
- [X] T013 [P] [US3] Ensure `lib/ui.sh` has no side effects at load time — only define color variables and functions
- [X] T014 [P] [US3] Ensure `lib/credentials.sh` has no side effects at load time — `check_credentials` should only run when called

**Checkpoint**: All four libraries can be sourced independently without errors.

---

## Phase 4: User Story 1 - Core Script Still Works Identically (Priority: P1)

**Goal**: Verify that the refactored script behaves identically to the original — no behavioral changes.

**Independent Test**: Run `./godaddy-cname.sh` and validate all prompts, colors, navigation, and API flows match the original.

- [X] T015 [US1] Run `bash -n godaddy-cname.sh && bash -n lib/*.sh` to verify syntax on all files
- [X] T016 [US1] Run `source lib/json.sh && source lib/api.sh && source lib/ui.sh && source lib/credentials.sh` to verify all libraries can be sourced together
- [X] T017 [US1] Test `json_count` manually: `source lib/json.sh && result=$(json_count '[{"name":"test"}]') && [ "$result" = "1" ] && echo "PASS"`
- [X] T018 [US1] Does not apply (no jq fallback test needed for this refactor — existing fallback logic is preserved)
- [X] T019 [US1] Do a full TUI smoke test: run `./godaddy-cname.sh` and navigate all menu options (list, add, edit, delete, back, quit)
- [X] T020 [US1] Verify no `.env` or credential leakage in library files — `grep -n 'GODADDY_API_KEY\|GODADDY_API_SECRET' lib/*.sh` should only show reference usage, not hardcoded values
- [X] T021 [US1] Verify no function name conflicts: `grep -E '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' lib/*.sh godaddy-cname.sh | sort | uniq -d` should return empty

**Checkpoint**: All syntax checks, sourceability, and functional tests pass. Script behavior matches pre-refactor.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup, documentation, and quality verification.

- [X] T022 [P] Update `Dockerfile` to copy `lib/` directory
- [X] T022b [P] Update `README.md` to mention the `lib/` directory structure
- [X] T023 [P] Clean up any stale temporary files references
- [X] T024 Run the `quickstart.md` validation checklist end-to-end

**Checkpoint**: All phases complete, script is refactored and verified.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **US2 - Library Extraction (Phase 2)**: Depends on Setup — this is the core work
- **US3 - Individually Testable (Phase 3)**: Depends on US2 — libraries must exist to test them
- **US1 - Behavioral Preservation (Phase 4)**: Depends on US2 and US3 — must verify the final state
- **Polish (Phase 5)**: Depends on all prior phases

### User Story Dependencies

- **User Story 2 (P1) - US2**: Extraction — can start after Phase 1. The main work.
- **User Story 3 (P2) - US3**: Testability — depends on US2 being extracted.
- **User Story 1 (P1) - US1**: Verification — depends on US2 and US3.

### Parallel Opportunities

- T003, T004, T005, T006 can run in parallel (each extracts a different library file)
- T011, T012, T013, T014 can run in parallel (each checks a different library)

---

## Parallel Example: Phase 2 (US2)

```bash
# Extract all four libraries in parallel:
Task: "Extract json helpers into lib/json.sh"
Task: "Extract API helpers into lib/api.sh"
Task: "Extract UI helpers into lib/ui.sh"
Task: "Extract credentials into lib/credentials.sh"
```

---

## Implementation Strategy

### MVP (Phase 1 + Phase 2)

1. Complete Phase 1: Setup (create `lib/`)
2. Complete Phase 2: Extract all four libraries and update main script sourcing
3. **STOP and VALIDATE**: Run `./godaddy-cname.sh` and verify it works

### Incremental Delivery

1. Phase 1 + Phase 2 → Extraction complete, script works
2. Phase 3 → Libraries independently testable
3. Phase 4 → Full behavioral verification
4. Phase 5 → Polish

### Notes

- [P] tasks = different files, no dependencies
- Each library extraction task should: copy the function, add a header, and remove from main script
- Run `bash -n` after each extraction to catch syntax errors early
- Commit after each logical group of tasks
