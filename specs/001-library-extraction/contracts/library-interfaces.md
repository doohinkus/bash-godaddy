# Library Interface Contracts

## `lib/json.sh` — JSON Helpers

```
json_fields(json: str, field: str) -> stdout: lines
json_field_at(json: str, field: str, idx: int) -> stdout: single value
json_record(name: str, data: str, ttl: int) -> stdout: JSON string
json_filter_out(json: str, exclude_name: str) -> stdout: filtered JSON array
json_count(json: str) -> stdout: integer count
```

**Contract**: All functions accept JSON as first positional argument. Output is written to stdout. Errors are silent (empty output). Functions must work with both `jq` (preferred) and grep/sed fallback.

## `lib/api.sh` — API Communication

```
api_get(path: str) -> stdout: API response body
api_patch(path: str, payload: str) -> stdout: API response body
api_put(path: str, payload: str) -> stdout: API response body
```

**Contract**: All functions use `$AUTH` header and `$GODADDY_BASE_URL` for the base URL. Functions return raw API response to stdout. Empty response = success (for PATCH/PUT).

## `lib/ui.sh` — TUI Utilities

```
Variables: $R $G $Y $B $P $C $GR $BO $NC (ANSI color codes)

clear_screen()
print_header(title: str)
pause()
confirm(prompt: str) -> exit code: 0=yes, 1=no
```

**Contract**: All output goes to stderr except `confirm` which uses exit codes. Colors are reset after each call via `$NC`.

## `lib/credentials.sh` — Credential Management

```
check_credentials() -> exit code: 0=ok, 1=missing
Side effect: sets $AUTH global variable
```

**Contract**: Reads `$GODADDY_API_KEY` and `$GODADDY_API_SECRET` from environment or `.env` file. If missing, prompts interactively. Input is read with `-s` flag to suppress echo for secrets.
