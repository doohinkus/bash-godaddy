# Feature Specification: TXT Record Management

**Feature**: `specs/002-txt-record-management`

**Created**: 2026-05-14

**Status**: Draft

**Input**: User description: "add TXT record management to the GoDaddy DNS tool, alongside the existing CNAME support"

## User Scenarios & Testing

### User Story 1 - Switch Between CNAME and TXT Record Types (Priority: P1)

From the main record management view for a domain, the user can toggle between viewing CNAME records and TXT records. A header or status indicator shows which record type is currently active.

**Why this priority**: The user cannot manage TXT records without a way to access them. This is the entry point.

**Independent Test**: Open a domain's record view. See CNAME records by default. Switch to TXT view and see TXT records. Switch back to CNAME.

**Acceptance Scenarios**:
1. **Given** the user is viewing records for a domain, **When** the page loads, **Then** CNAME records are shown by default
2. **Given** CNAME records are displayed, **When** the user selects the "switch type" action, **Then** TXT records are fetched and displayed
3. **Given** TXT records are displayed, **When** the user switches back, **Then** CNAME records are shown again
4. **Given** either record type is active, **When** the user refreshes, **Then** the current type's records are re-fetched

---

### User Story 2 - List TXT Records (Priority: P1)

When TXT mode is active, the script fetches and displays all TXT records for the domain in a table with name, data (text value), and TTL columns.

**Why this priority**: Users need to see existing TXT records before they can manage them.

**Independent Test**: Switch to TXT mode and verify TXT records are displayed in a formatted table.

**Acceptance Scenarios**:
1. **Given** TXT mode is active and the domain has TXT records, **When** records are fetched, **Then** they appear in a table with Name, Data, and TTL columns
2. **Given** TXT mode is active and the domain has no TXT records, **When** records are fetched, **Then** a "No TXT records found" message is shown

---

### User Story 3 - Add, Edit, and Delete TXT Records (Priority: P1)

While in TXT mode, the user can add new TXT records, edit existing TXT records, and delete TXT records using the same interactive prompts as CNAME management.

**Why this priority**: Full TXT management requires CRUD operations.

**Independent Test**: Switch to TXT mode. Add a new TXT record. Verify it appears in the list. Edit it. Delete it.

**Acceptance Scenarios**:
1. **Given** TXT mode is active, **When** the user chooses "Add" and provides name, data, and TTL, **Then** the TXT record is created via API PATCH and confirmed
2. **Given** TXT mode and an existing TXT record, **When** the user edits it and changes the text value, **Then** the record is updated via API PATCH
3. **Given** TXT mode and an existing TXT record, **When** the user deletes it and confirms, **Then** the record is removed via API GET+PUT filter

---

### Edge Cases

- What happens when a TXT record has special characters (quotes, spaces) in the data field? JSON escaping must handle this.
- TXT records can have multiple values with the same name (TXT is multivalued). The current approach (treating name as identifier) may need to use name+data as the composite identifier for editing/deleting.
- What if the API returns errors for TXT endpoints (e.g., domain doesn't support TXT records)?

## Requirements

### Functional Requirements

- **FR-001**: The record type (CNAME/TXT) MUST be toggleable from the record management view
- **FR-002**: The current record type MUST be displayed in the header (e.g., "CNAME Records: example.com" vs "TXT Records: example.com")
- **FR-003**: TXT records MUST be fetched from `/v1/domains/{domain}/records/TXT`
- **FR-004**: TXT record display MUST show Name, Data (text value), and TTL columns
- **FR-005**: Adding a TXT record MUST PATCH `/v1/domains/{domain}/records` with a TXT-type record payload
- **FR-006**: Editing a TXT record MUST use the same PATCH approach (replacement of all TXT records)
- **FR-007**: Deleting a TXT record MUST use GET+PUT filter (same pattern as CNAME delete)
- **FR-008**: The existing CNAME management functionality MUST remain unchanged
- **FR-009**: The record type selection MUST persist during a session (not reset on refresh)

### Key Entities

- **Record type**: An enum-like state (CNAME or TXT) that determines which API endpoint and display format is used
- **TXT record**: Has `name`, `data` (text string), and `ttl` fields — same structure as CNAME records in the GoDaddy API

## Success Criteria

### Measurable Outcomes

- **SC-001**: User can switch between CNAME and TXT views in 2 keystrokes or fewer
- **SC-002**: TXT records are displayed with the same formatting quality as existing CNAME records
- **SC-003**: All CRUD operations for TXT records complete without API errors for valid inputs
- **SC-004**: CNAME functionality is completely unaffected by the TXT additions — all existing flows work identically
- **SC-005**: The script size increase does not exceed 15% of the current line count

## Assumptions

- The GoDaddy API supports TXT records with the same PATCH/PUT semantics as CNAME records
- TXT record data values may contain spaces and special characters that require JSON escaping
- The existing `json_record` helper can be extended to support different record types (not just CNAME)
- Users manage either CNAME or TXT records at a time, not both simultaneously
- No changes needed to Dockerfile, README, or credential handling
