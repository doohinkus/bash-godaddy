<!--
Sync Impact Report:
- Version change: 0.1.0 (initial)
- No previous version
- All sections newly created
- Templates: ✅ constitution-template.md filled, plan-template.md reviewed
-->

# bash-godaddy Constitution

## Core Principles

### I. Simplicity First
Shell scripts are linear by nature. Keep the script single-file unless complexity proves otherwise. Avoid unnecessary abstractions, wrapping, or premature modularization. Use bash built-ins and curl directly rather than introducing wrapper layers. Every function must have one clear responsibility.

### II. Robustness & Error Handling
All operations must validate inputs, check API responses, and fail gracefully with clear user-facing messages. Use `set -euo pipefail`. Every curl call must check for HTTP errors. Never silently swallow failures — show the user what went wrong and why.

### III. Developer Experience (TUI)
The terminal UI must be intuitive, self-documenting, and consistent. Use clear color-coded prompts (red for errors, green for success, yellow for confirmations). Always provide a back option and clear navigation. Include sensible defaults in prompts (e.g., TTL=3600).

### IV. Portability
Support bash 3+ (macOS default) and avoid bash 4+ only features. Prefer POSIX-compatible constructs where practical. `jq` is optional — provide grep/sed fallbacks for JSON parsing. Docker must remain a first-class deployment option.

### V. API Safety
All GoDaddy API mutations (PATCH, PUT) must confirm with the user before executing. Credentials must never be logged or exposed. Support `.env` file loading and environment variables equally. Rate-limit awareness — batch operations should be avoided.

## Security & Credentials

API keys and secrets are sensitive. The `.env` file is gitignored by default. Never echo secrets to stdout. Never pass credentials in URLs or logs. The script must prompt for missing credentials interactively rather than failing cryptically.

## Development Workflow

- All changes go through feature branches using `speckit.git.feature`
- Test manually with both `jq` available and unavailable (fallback path)
- Run against OTE environment first when possible (`GODADDY_BASE_URL=https://api.ote-godaddy.com`)
- Commit messages follow conventional commits format via `speckit.git.commit`
- Maintain backward compatibility — do not break existing prompt flows or environment variable contracts

## Governance

This constitution governs all development in this repository. Amendments require documented rationale and a migration plan. All PRs must verify compliance with these principles. Complexity must be justified — when in doubt, choose the simpler approach.

**Version**: 0.1.0 | **Ratified**: 2026-05-14 | **Last Amended**: 2026-05-14
