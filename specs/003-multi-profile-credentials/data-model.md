# Data Model: Multi-Profile Credentials

## Entity: Profile

A profile is a named set of GoDaddy API credentials stored in a `.env`-format file under `profiles/`.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | `string` | Yes | — | Profile label derived from filename stem (e.g., "production" from `profiles/production.env`). Lowercase alphanumeric. |
| `api_key` | `string` | Yes | — | GoDaddy API key (SSO key). Must be non-empty. |
| `api_secret` | `string` | Yes | — | GoDaddy API secret. Must be non-empty. |
| `base_url` | `string` | No | `https://api.godaddy.com` | Custom GoDaddy API base URL (e.g., `https://api.ote-godaddy.com`). |

### Validation Rules

1. **Filename pattern**: Must match `<name>.env` where `name` matches `[a-zA-Z0-9_-]+`
2. **Required vars**: `GODADDY_API_KEY` and `GODADDY_API_SECRET` must be present and non-empty
3. **Optional vars**: `GODADDY_BASE_URL` — if present, must be a valid URL
4. **Syntax**: File must be valid shell-sourcable `.env` format (key=value pairs)
5. **Empty files**: Skipped with a warning
6. **Invalid/syntax-error files**: Error displayed, user returned to profile menu

### State Transitions

```
STARTUP → scan profiles/
         ├── 0 profiles → fallback to .env/interactive (no state)
         ├── 1 profile  → auto-select → ACTIVE 
         └── 2+ profiles → show menu → user selects → ACTIVE
         
ACTIVE → PROFILE_NAME is set → all API calls use this profile's credentials
       → profile name displayed in headers

ACTIVE (on error sourcing a profile) → return to profile menu
                                     → if all profiles invalid → fallback to interactive
```

## Entity: Active Profile (runtime state)

| Variable | Type | Description |
|----------|------|-------------|
| `ACTIVE_PROFILE` | `string` | Current profile name, or empty if using `.env` fallback |
| `GODADDY_API_KEY` | `string` | Resolved from active profile or `.env` |
| `GODADDY_API_SECRET` | `string` | Resolved from active profile or `.env` |
| `GODADDY_BASE_URL` | `string` | Resolved from active profile or `.env` or default |
| `AUTH` | `string` | `Authorization: sso-key <key>:<secret>` | header |

## File: profiles/<name>.env

```
GODADDY_API_KEY=your_api_key_here
GODADDY_API_SECRET=your_api_secret_here
GODADDY_BASE_URL=https://api.godaddy.com  # optional
```
