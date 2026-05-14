# Tasks: TXT Record Management

**Input**: Design documents from `specs/002-txt-record-management/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Parameterize helpers for record type support

- [X] T001 Parameterize `json_record` in `lib/json.sh` by adding a `type` argument (default `CNAME`), updating the existing function callers
- [X] T002 Add `json_txt_record` wrapper function in `lib/json.sh` that calls `json_record` with `type=TXT` for backwards compatibility clarity

**Checkpoint**: `lib/json.sh` can produce both CNAME and TXT record payloads

---

## Phase 2: User Story 1 - Record Type Toggle (Priority: P1)

**Goal**: User can switch between CNAME and TXT mode from the record management view.

**Independent Test**: Open a domain's records, press `t`, see header change from "CNAME Records" to "TXT Records". Press `t` again, see it switch back.

- [X] T003 [US1] Add `RECORD_TYPE` global variable initialized to `CNAME` in `godaddy-cname.sh`
- [X] T004 [US1] Add `t` toggle action to the `manage_records` action menu in `godaddy-cname.sh` that flips `RECORD_TYPE` between `CNAME` and `TXT`
- [X] T005 [US1] Update the `manage_records` header to display the current record type dynamically: `"${RECORD_TYPE} Records: $domain"`

**Checkpoint**: Toggle works — header changes, no records fetched yet on toggle (fetch happens on refresh/loop iteration)

---

## Phase 3: User Story 2 - List TXT Records (Priority: P1)

**Goal**: When TXT mode is active, fetch and display TXT records in a formatted table.

**Independent Test**: Toggle to TXT mode and verify TXT records are listed with correct columns and formatting.

- [X] T006 [US2] Parameterize the API endpoint in `manage_records` to use `/v1/domains/$domain/records/$RECORD_TYPE` for fetching records (was hardcoded to CNAME)
- [X] T007 [US2] Update header label in `manage_records` to use `$RECORD_TYPE` in the section header
- [X] T008 [US2] Verify the "No TXT records found" message appears when there are zero TXT records

**Checkpoint**: TXT records display correctly in the same table format as CNAME records.

---

## Phase 4: User Story 3 - Add, Edit, Delete TXT Records (Priority: P1)

**Goal**: Full CRUD operations for TXT records, reusing the existing function pattern.

**Independent Test**: Add a TXT record, verify it appears in the list. Edit it. Delete it.

- [X] T009 [P] [US3] Parameterize `add_record` in `godaddy-cname.sh` to use `$RECORD_TYPE` for the API endpoint and `json_record` type
- [X] T010 [P] [US3] Parameterize `edit_record` in `godaddy-cname.sh` to use `$RECORD_TYPE` for the API endpoint and `json_record` type
- [X] T011 [P] [US3] Parameterize `delete_record` in `godaddy-cname.sh` to use `$RECORD_TYPE` for the API endpoint and `json_filter_out` / `json_record` type

**Checkpoint**: All three CRUD operations work for TXT records with the same UX as CNAME.

---

## Phase 5: Verification & Polish

**Purpose**: Syntax check, regression test CNAME, smoke test TXT.

- [X] T012 Run `bash -n godaddy-cname.sh && bash -n lib/json.sh` to verify syntax
- [X] T013 Run `source lib/json.sh && json_record "test" "value" 3600 && json_record "test" "value" 3600 TXT` to verify backward compatibility
- [X] T014 Do a full smoke test: CNAME flow unchanged (list, add, edit, delete)
- [X] T015 Do a TXT smoke test: toggle, list, add, edit, delete TXT records
- [X] T016 Commit the changes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **US1 - Toggle (Phase 2)**: Depends on Phase 1
- **US2 - List TXT (Phase 3)**: Depends on Phase 2
- **US3 - CRUD TXT (Phase 4)**: Depends on Phase 3
- **Verification (Phase 5)**: Depends on Phase 4

### User Story Dependencies

- All three user stories build on each other — US3 needs US2's listing, US2 needs US1's toggle

### Parallel Opportunities

- T009, T010, T011 can run in parallel (modify different functions in the same file though — sequential is safer for same-file edits)

---

## Implementation Strategy

### Implementation Note

T003-T011 all modify `godaddy-cname.sh`. The approach is to:
1. First add `RECORD_TYPE` variable and the `t` key handler (T003-T004)
2. Then parameterize the API endpoint in `manage_records` (T006)
3. Then parameterize add/edit/delete (T009-T011)
4. Handle the header display (T005, T007) as part of the manage_records updates

All changes are additive — existing CNAME behavior is preserved by the default `RECORD_TYPE=CNAME`.
