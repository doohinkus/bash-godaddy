# Feature Specification: Multi-Profile Credentials

**Feature**: `specs/003-multi-profile-credentials`

**Created**: 2026-05-14

**Status**: Draft

**Input**: User description: "add multi-profile credentials support to switch between multiple GoDaddy API accounts"

## User Scenarios & Testing

### User Story 1 - Profile Selection Menu (Priority: P1)

When the script starts and multiple credential profiles exist, the user is shown a numbered menu to select which profile to use. If only one profile exists, it is used automatically without a menu.

**Why this priority**: The profile selection is the entry point for the entire feature — without it, nothing else works.

**Independent Test**: Create two profile files in `profiles/`. Run the script and see a profile selection menu before the domain list.

**Acceptance Scenarios**:
1. **Given** multiple profiles exist in `profiles/`, **When** the script starts, **Then** a numbered profile selection menu is displayed before the domain list
2. **Given** exactly one profile exists in `profiles/`, **When** the script starts, **Then** it is used automatically with no profile menu
3. **Given** no profiles exist, **When** the script starts, **Then** the existing interactive credential prompt is shown (backward compatible)
4. **Given** a profile is selected, **When** the session continues, **Then** that profile's credentials are used for all API calls

---

### User Story 2 - Profile File Format (Priority: P1)

Profiles are stored as individual `.env` files in a `profiles/` directory. Each file follows the existing `.env` convention with `GODADDY_API_KEY`, `GODADDY_API_SECRET`, and optionally `GODADDY_BASE_URL`.

**Why this priority**: Without a defined format, users cannot create profiles.

**Independent Test**: Create a file `profiles/ote.env` with valid credentials and verify it is discovered by the script.

**Acceptance Scenarios**:
1. **Given** a file `profiles/production.env` exists with API credentials, **When** the script scans for profiles, **Then** "production" appears as an option in the profile menu
2. **Given** a profile file with `GODADDY_BASE_URL` set, **When** the profile is selected, **Then** the custom base URL is used for API calls
3. **Given** a profile file without `GODADDY_BASE_URL`, **When** the profile is selected, **Then** the default GoDaddy API URL is used

---

### User Story 3 - Profile-Aware Session (Priority: P2)

The selected profile name is displayed in the main header and record management views, so the user always knows which account they are operating on.

**Why this priority**: Users need to avoid accidentally modifying the wrong account's DNS records.

**Independent Test**: Select "ote" profile, verify the header shows "OTE" in the title.

**Acceptance Scenarios**:
1. **Given** the "production" profile is active, **When** viewing the main menu, **Then** the header shows "GoDaddy CNAME Manager [production]"
2. **Given** the "ote" profile is active, **When** viewing records, **Then** the header shows "CNAME Records: domain.com [ote]"

---

### Edge Cases

- What if a profile file has syntax errors or missing required variables? Show an error and return to the profile selection menu.
- What if all profile files are invalid? Fall back to interactive credential prompt.
- What if the `profiles/` directory doesn't exist? Fall back to existing `.env` behavior.
- What if a profile file is empty? Skip it with a warning.

## Requirements

### Functional Requirements

- **FR-001**: Profiles MUST be stored as individual `.env`-format files in a `profiles/` directory at the project root
- **FR-002**: Profile filenames MUST follow the pattern `<name>.env` where `<name>` is the profile label
- **FR-003**: The script MUST scan `profiles/` at startup and present a selection menu if 2+ profiles are found
- **FR-004**: If exactly one profile exists, it MUST be auto-selected without a menu
- **FR-005**: If no profiles exist, the script MUST fall back to the existing `.env` + interactive prompt behavior
- **FR-006**: The selected profile name MUST be displayed in the main header
- **FR-007**: Profile files MUST support `GODADDY_API_KEY`, `GODADDY_API_SECRET`, and optional `GODADDY_BASE_URL`
- **FR-008**: The existing `.env` file at the project root MUST continue to work when no profiles exist
- **FR-009**: The `profiles/` directory MUST be added to `.gitignore`

### Key Entities

- **Profile**: A named set of GoDaddy API credentials stored in a `.env`-format file under `profiles/`
- **Profile selector**: A TUI menu at startup that lists available profiles
- **Active profile**: The currently selected profile, tracked in a variable and displayed in headers

## Success Criteria

### Measurable Outcomes

- **SC-001**: User can switch between 2+ accounts in under 5 seconds (3 keystrokes)
- **SC-002**: Existing `.env`-only users see zero change in behavior
- **SC-003**: The active profile name is visible on every screen
- **SC-004**: Invalid profile files never crash the script — they show an error and let the user pick again

## Assumptions

- Profile files are small (one per account, typically 2-5 files)
- Users will create profiles manually by copying `.example.env` or existing profiles
- The `profiles/` directory is in `.gitignore` to prevent credential leakage
- Profile names are lowercase alphanumeric (derived from filename)
