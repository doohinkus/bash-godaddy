# Quickstart: Multi-Profile Credentials

## Creating Profiles

Create `.env` files in the `profiles/` directory at the project root:

```bash
mkdir -p profiles
```

### Example: `profiles/production.env`

```
GODADDY_API_KEY=your_production_key
GODADDY_API_SECRET=your_production_secret
```

### Example: `profiles/ote.env` (OTE testing environment)

```
GODADDY_API_KEY=your_ote_key
GODADDY_API_SECRET=your_ote_secret
GODADDY_BASE_URL=https://api.ote-godaddy.com
```

The profile name is derived from the filename stem: `profiles/production.env` becomes profile `production`.

## Running

Just run the script as normal:

```bash
./godaddy-cname.sh
```

If multiple profiles exist, you'll see a numbered menu at startup. Select one and proceed.

## Backward Compatibility

- No `profiles/` directory → works exactly as before (loads `.env` + interactive prompt)
- Exactly one profile → auto-selected silently
- Existing `.env` at project root is unaffected (still loaded for environment variable fallback)

## `.gitignore`

Add `profiles/` to `.gitignore` to prevent credential leakage.
