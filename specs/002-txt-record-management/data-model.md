# Data Model: TXT Record Management

### Record Type State

| Variable | Type | Values | Description |
|----------|------|--------|-------------|
| `RECORD_TYPE` | string | `CNAME` or `TXT` | Current active record type, set on toggle |

### Modified Functions

| Function | Current Signature | New Signature | Change |
|----------|-------------------|---------------|--------|
| `json_record` | `json_record(name, data, ttl)` | `json_record(name, data, ttl, type)` | Added `type` parameter (default: `CNAME`) |
| `manage_records` | `manage_records(domain)` | `manage_records(domain, record_type)` | Added `record_type` parameter |
| `add_record` | `add_record(domain)` | `add_record(domain, record_type)` | Added `record_type` parameter |
| `edit_record` | `edit_record(domain)` | `edit_record(domain, record_type)` | Added `record_type` parameter |
| `delete_record` | `delete_record(domain)` | `delete_record(domain, record_type)` | Added `record_type` parameter |

### New Functions

None — the existing 4 CRUD functions are parameterized. The toggle action is handled inline in `manage_records`.

### Global Variables Added

| Variable | Set by | Used by |
|----------|--------|---------|
| `RECORD_TYPE` | `manage_records` (initialized as `CNAME`, toggled inline) | All management functions to build correct API endpoint and payload |
