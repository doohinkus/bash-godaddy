# Feature Specification: Library Extraction Refactor

**Feature**: `specs/001-library-extraction`

**Created**: 2026-05-14

**Status**: Draft

**Input**: User description: "refactor the monolithic godaddy-cname.sh script by extracting reusable helper libraries"

## User Scenarios & Testing

### User Story 1 - Core Script Still Works Identically (Priority: P1)

After the refactor, the user runs `./godaddy-cname.sh` and experiences the exact same TUI workflow — listing domains, viewing CNAME records, adding, editing, and deleting records. No behavior changes, no new prompts, no broken flows.

**Why this priority**: The refactor must be invisible to end users. If the script breaks, the refactor has failed.

**Independent Test**: Run the script and navigate through list → add → edit → delete flows. Verify all prompts, colors, and navigation behave exactly as before.

**Acceptance Scenarios**:
1. **Given** a working GoDaddy API configuration, **When** the user runs `./godaddy-cname.sh`, **Then** the same menu and domain selection flow appears
2. **Given** a domain with CNAME records, **When** the user lists records, **Then** the same table format, colors, and column alignment appear
3. **Given** a domain, **When** the user adds, edits, or deletes a CNAME record, **Then** the exact same prompts, confirmations, and success/error messages appear

---

### User Story 2 - Library Files Are Sourced from `lib/` (Priority: P1)

Helper functions are extracted into separate files under `lib/` and sourced by the main script. Each library file has a single responsibility.

**Why this priority**: This is the core deliverable of the refactor — modular, maintainable libraries.

**Independent Test**: Source each library file individually in a bash shell and verify its functions are available without side effects.

**Acceptance Scenarios**:
1. **Given** the library files in `lib/`, **When** sourced individually, **Then** each exposes only its domain-specific functions
2. **Given** the main script, **When** it starts, **Then** it sources all library files before executing any logic
3. **Given** a library file, **When** examined, **Then** it has no side effects at load time (no global state mutation)

---

### User Story 3 - Each Library Is Individually Testable (Priority: P2)

Library files can be sourced and tested independently via a simple bash one-liner or test harness.

**Why this priority**: Modularity enables easier maintenance, testing, and future reuse.

**Independent Test**: Source a library file, call one of its functions with test inputs, and verify the output.

**Acceptance Scenarios**:
1. **Given** `lib/json.sh`, **When** sourced and `json_count` is called with a test JSON string, **Then** it returns the correct count
2. **Given** `lib/api.sh`, **When** sourced without credentials loaded, **Then** it does not error at load time

---

### Edge Cases

- What happens if a library file is missing or unreadable? The script should error with a clear message indicating which file is missing.
- What happens if a library file has syntax errors? The `source` should fail fast with bash's error message pointing to the faulty file.
- What if the user runs the script from a different working directory? All source paths must be relative to `SCRIPT_DIR`, not `$PWD`.

## Requirements

### Functional Requirements

- **FR-001**: JSON helper functions MUST be extracted into `lib/json.sh`
- **FR-002**: API communication functions MUST be extracted into `lib/api.sh`
- **FR-003**: TUI helper functions (colors, prompts, formatting) MUST be extracted into `lib/ui.sh`
- **FR-004**: Credential management functions MUST be extracted into `lib/credentials.sh`
- **FR-005**: The main script MUST source all library files at startup using paths relative to its own directory
- **FR-006**: Each library file MUST NOT have side effects when sourced (no global commands executed)
- **FR-007**: All existing CLI behavior MUST be preserved identically — no changes to prompts, messages, colors, or navigation flow
- **FR-008**: The `.env` file loading MUST remain in the main script (sourced before libraries)
- **FR-009**: Temporary file cleanup (`cleanup` / `trap`) MUST remain in the main script

### Key Entities

- **Library files**: Standalone bash scripts under `lib/`, each containing related helper functions
- **Main script** (`godaddy-cname.sh`): The entry point that sources libraries and orchestrates the TUI workflow
- **Function names**: Must remain unchanged post-extraction so the main script's orchestration code does not need rewriting

## Success Criteria

### Measurable Outcomes

- **SC-001**: The main script produces byte-identical output (stdout and stderr) for all menu flows compared to its pre-refactor version, given identical inputs and API responses
- **SC-002**: Each library file can be sourced independently without error
- **SC-003**: The total line count of `lib/*.sh` + `godaddy-cname.sh` does not exceed 110% of the original single-file line count
- **SC-004**: No duplicate function definitions exist across library files
- **SC-005**: No credential or API key can leak through library file output or error messages

## Assumptions

- The existing function names, signatures, and global variable names will be preserved to minimize orchestration code changes
- No new functionality is being added — this is a pure structural refactor
- Dockerfile does not need changes since library files are sourced at runtime from the same directory
- The user's existing `.env` configuration remains valid without changes
- `bash` versions 3+ are still the target — library files must avoid bash 4+ only features (associative arrays, `**` globs, etc.)
