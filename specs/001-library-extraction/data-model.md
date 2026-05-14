# Data Model: Library Extraction Refactor

No traditional data model applies — this is a structural refactor of a bash script.

### Function Contracts (Interface)

Each library file exposes a set of bash functions. These signatures must be preserved.

#### `lib/json.sh`

| Function | Signature | Returns |
|---|---|---|
| `json_fields` | `json_fields(json, field)` | Lines of field values (stdout) |
| `json_field_at` | `json_field_at(json, field, idx)` | Single field value at index (stdout) |
| `json_record` | `json_record(name, data, ttl)` | JSON string `{"name":"...","data":"...","ttl":N,"type":"CNAME"}` |
| `json_filter_out` | `json_filter_out(json, exclude_name)` | Filtered JSON array (stdout) |
| `json_count` | `json_count(json)` | Integer count (stdout) |

#### `lib/api.sh`

| Function | Signature | Returns |
|---|---|---|
| `api_get` | `api_get(path)` | API response body (stdout) |
| `api_patch` | `api_patch(path, payload)` | API response body (stdout) |
| `api_put` | `api_put(path, payload)` | API response body (stdout) |

#### `lib/ui.sh`

| Exports | Type | Description |
|---|---|---|
| `R`, `G`, `Y`, `B`, `P`, `C`, `GR`, `BO`, `NC` | Variables | ANSI color escape codes |
| `clear_screen` | Function | `clear_screen()` — clears terminal |
| `print_header` | Function | `print_header(title)` — prints titled header |
| `pause` | Function | `pause()` — waits for Enter key |
| `confirm` | Function | `confirm(prompt)` → 0 (yes) / 1 (no) |

#### `lib/credentials.sh`

| Function | Signature | Returns |
|---|---|---|
| `check_credentials` | `check_credentials()` | 0 (ok) / 1 (missing) — also sets `AUTH` header |
| `AUTH` | Variable | Set as side effect of `check_credentials` |

### Global Variables (shared across all files)

| Variable | Set by | Used by |
|---|---|---|
| `AUTH` | `credentials.sh` (or main, on interactive input) | `api.sh` (all functions) |
| `GODADDY_API_KEY`, `GODADDY_API_SECRET` | `.env` or interactive prompt by `credentials.sh` | `credentials.sh` |
| `GODADDY_BASE_URL` | `.env` or default | `api.sh` (all functions) |
| `SCRIPT_DIR` | `godaddy-cname.sh` (line 12) | All `lib/*.sh` (path resolution), main (`.env` loading) |
