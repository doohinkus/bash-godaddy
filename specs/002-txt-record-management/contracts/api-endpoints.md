# API Endpoint Contracts

TXT records use the same GoDaddy API endpoints as CNAME, with the record type substituted in the path.

### List TXT Records

```
GET /v1/domains/{domain}/records/TXT
Headers: Authorization: sso-key {key}:{secret}
         Accept: application/json
Response: [{"name":"...","data":"...","ttl":600,"type":"TXT"}, ...]
```

### Add/Update TXT Record (PATCH)

```
PATCH /v1/domains/{domain}/records
Headers: Authorization: sso-key {key}:{secret}
         Content-Type: application/json
Body: [{"name":"...","data":"...","ttl":600,"type":"TXT"}]
Response: 200 OK (empty body) or error JSON
```

### Replace TXT Records (PUT — for deletion)

```
PUT /v1/domains/{domain}/records/TXT
Headers: Authorization: sso-key {key}:{secret}
         Content-Type: application/json
Body: [{"name":"...","data":"...","ttl":600,"type":"TXT"}, ...]
Response: 200 OK (empty body) or error JSON
```
