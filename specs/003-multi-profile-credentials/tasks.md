# Tasks: Multi-Profile Credentials

**Branch**: `003-multi-profile-credentials` | **Date**: 2026-05-14

## ✅ Task 1: Scaffold `profiles/` directory and update `.gitignore`

**File(s)**: `.gitignore`

**Est**: 5 min

**Subtasks**:
1. Add `profiles/` to `.gitignore` (after the existing `.env` line)
2. Create `profiles/` directory at project root

**Acceptance**: `profiles/` exists at root and is gitignored.

---

## ✅ Task 2: Add profile loading functions to `lib/credentials.sh`

**File(s)**: `lib/credentials.sh`

**Est**: 20 min

**Subtasks**:
1. Implement `load_profiles()`:
   - Check if `profiles/` directory exists → exit early if missing (empty list)
   - Loop `for f in "profiles/"*.env; do`
     - Strip `.env` suffix → derive profile name from filename
     - Skip if file isn't readable or is empty
     - Validate the file contains non-empty `GODADDY_API_KEY` and `GODADDY_API_SECRET` (source + check)
     - Append valid profile names to `_PROFILES` (newline-separated string, bash 3 compatible)
     - Invalid/empty files → print warning and skip
   - Count lines in `_PROFILES` to determine available profiles
2. Implement `select_profile()`:
   - `load_profiles()` first
   - Case 0 profiles → return empty string (triggers fallback)
   - Case 1 profile → return its name (auto-select)
   - Case 2+ profiles → render `select` menu with numbered list, re-prompt on invalid
   - Return selected profile name
3. Implement `apply_profile(name)`:
   - Source `profiles/${name}.env`
   - Rebuild `AUTH` header from sourced credentials
   - Set `ACTIVE_PROFILE="${name}"` globally
   - If `GODADDY_BASE_URL` is not set in the profile, default to `https://api.godaddy.com`

**Acceptance**:
- 0 profiles → empty return
- 1 profile → auto-selected, no menu
- 2+ profiles → numbered `select` menu shown
- Invalid profile file → warning + skip, not crash
- All invalid → fallback to empty (which triggers interactive prompt)

---

## ✅ Task 3: Update `lib/ui.sh` to display active profile

**File(s)**: `lib/ui.sh`

**Est**: 10 min

**Subtasks**:
1. Modify `print_header()` to accept an optional second parameter `profile_name`
2. If `profile_name` is non-empty, render header as `=== title [profile_name] ===`
3. Keep existing behavior unchanged when profile name is empty

**Acceptance**:
- `print_header "Foo"` → `=== Foo ===`
- `print_header "Foo" "production"` → `=== Foo [production] ===`

---

## ✅ Task 4: Integrate profile loading into `godaddy-cname.sh`

**File(s)**: `godaddy-cname.sh`

**Est**: 15 min

**Subtasks**:
1. After sourcing all libs but before `check_credentials`, call `select_profile()`:
   - If a profile is selected, `apply_profile()` it
   - If no profiles exist, leave existing `.env` sourcing + interactive fallback in place
2. Update all `print_header` calls in `main()` and `manage_records()` to pass `$ACTIVE_PROFILE` as second argument
3. Call `print_header "GoDaddy CNAME Manager"` with profile name in `main()`
4. Call `print_header "${RECORD_TYPE} Records: $domain"` with profile name in `manage_records()`
5. Update `print_header "Add ${RECORD_TYPE} Record"` in `add_record()`
6. Update `print_header "Edit ${RECORD_TYPE} Record"` in `edit_record()`
7. Update `print_header "Delete ${RECORD_TYPE} Record"` in `delete_record()`

**Acceptance**:
- Main menu header shows `GoDaddy CNAME Manager [profile]` when profile is active
- Record management header shows `CNAME Records: example.com [profile]`
- All `print_header` calls in record CRUD display the active profile
- Zero profiles → no `[]` suffix, backward compatible

---

## ✅ Task 5: Update `.example.env` to document profiles

**File(s)**: `.example.env`

**Est**: 5 min

**Subtasks**:
1. Add a comment block referencing the `profiles/` directory approach
2. Note that to use profiles, create `profiles/<name>.env` files instead of `.env`

**Acceptance**: `.example.env` mentions the `profiles/` convention.

---

All 5 tasks complete.
