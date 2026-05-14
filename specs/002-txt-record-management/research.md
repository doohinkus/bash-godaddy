# Research: TXT Record Management

## No Technical Unknowns

TXT records use the same GoDaddy API patterns as CNAME records. The implementation approach is well-understood.

### GoDaddy API for TXT Records

| Operation | Endpoint | Method |
|-----------|----------|--------|
| List TXT | `/v1/domains/{domain}/records/TXT` | GET |
| Add/update TXT | `/v1/domains/{domain}/records` | PATCH |
| Replace TXT | `/v1/domains/{domain}/records/TXT` | PUT |

The TXT record format is identical to CNAME: `{"name":"...","data":"...","ttl":3600,"type":"TXT"}`.

### Approach

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| Record type state variable (`RECORD_TYPE`) | Simplest approach — toggle between "CNAME" and "TXT" in a global variable | Separate TXT management functions — code duplication |
| Parameterize existing management functions | `manage_records`, `add_record`, `edit_record`, `delete_record` accept record type as argument | Separate functions per type — violates DRY |
| `json_record` type parameter | Add a `type` parameter to `json_record` so it can produce both CNAME and TXT payloads | Separate `json_txt_record` function — minimal duplication is OK for clarity |
| Single-key toggle (`t`) in the actions menu | Matches existing UX pattern (`a`, `e`, `d`, `r`, `b`, `q`) | Separate menu — unnecessary navigation depth |

### Files to Modify

| File | Changes |
|------|---------|
| `godaddy-cname.sh` | Add `RECORD_TYPE` variable, toggle action, parameterize existing functions to accept record type |
| `lib/json.sh` | Add `json_txt_record` function (or parameterize `json_record`) |

### TXT Record Details

- TXT data values are quoted strings — the GoDaddy API accepts them as JSON strings
- Multiple TXT records can share the same name (unlike CNAME which is unique). The delete/edit flow uses name as identifier, which may need name+data disambiguation for TXT.
- TTL minimum is 600 seconds (same as CNAME)
