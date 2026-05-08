# godaddy-cname

![godaddy-cname demo](godaddy-demo.gif)

Manage GoDaddy CNAME DNS records from the terminal.

A bash reimplementation of [tui-godaddy-cname](https://github.com/doohinkus/tui-godaddy).

## Usage

```bash
chmod +x godaddy-cname.sh
./godaddy-cname.sh
```

Or copy the example env file and edit with your credentials:

```bash
cp .example.env .env
# edit .env with your GoDaddy API key and secret
```

## Configuration

Set these environment variables (or create a `.env` file in the script directory):

| Variable | Description | Default |
|---|---|---|
| `GODADDY_API_KEY` | GoDaddy API key | — |
| `GODADDY_API_SECRET` | GoDaddy API secret | — |
| `GODADDY_BASE_URL` | API base URL | `https://api.godaddy.com` |

Get credentials at: https://developer.godaddy.com/keys

**OTE/testing:** Set `GODADDY_BASE_URL=https://api.ote-godaddy.com`

## Features

- List domains — pick one from a numbered menu
- View CNAME records — table with name, target, TTL
- Add records — prompted for subdomain, target, TTL
- Edit records — pre-filled prompts, PATCH to update
- Delete records — confirmation prompt, GET+PUT filter removal
- All API errors displayed inline with GoDaddy error messages

## Requirements

- bash 3+
- curl
- jq (optional — falls back to grep/sed for JSON parsing)

## API

Uses the [GoDaddy REST API](https://developer.godaddy.com/doc/endpoint/domains):

| Operation | Method | Endpoint |
|---|---|---|
| List domains | GET | `/v1/domains` |
| Get CNAME records | GET | `/v1/domains/{domain}/records/CNAME` |
| Add/update record | PATCH | `/v1/domains/{domain}/records` |
| Delete record | GET + PUT | GET all CNAMEs, filter, PUT replacement |
