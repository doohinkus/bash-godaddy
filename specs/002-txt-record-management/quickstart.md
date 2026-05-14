# Quickstart: TXT Record Management

## Verification Checklist

### 1. Syntax check

```bash
bash -n godaddy-cname.sh && bash -n lib/*.sh
```

### 2. CNAME still works (regression test)

```bash
./godaddy-cname.sh
```
- Select a domain
- Verify CNAME records load
- Add a CNAME record
- Edit it
- Delete it

### 3. TXT record management

```bash
./godaddy-cname.sh
```
- Select a domain
- Press `t` to switch to TXT mode
- Verify header shows "TXT Records: domain.com"
- Verify TXT records are displayed
- Press `a` to add a test TXT record
- Press `t` to switch back to CNAME mode
- Verify CNAME records still display correctly
- Switch back to TXT mode
- Edit the test TXT record
- Delete the test TXT record
- Press `q` to quit

### 4. json_record backward compatibility

```bash
source lib/json.sh
json_record "test" "value" 3600
# Expected: {"name":"test","data":"value","ttl":3600,"type":"CNAME"}
json_record "test" "value" 3600 TXT
# Expected: {"name":"test","data":"value","ttl":3600,"type":"TXT"}
```
