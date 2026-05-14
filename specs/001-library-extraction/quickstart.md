# Quickstart: Library Extraction Refactor

## Verification Checklist

Run these steps to verify the refactor is correct:

### 1. Syntax check all files

```bash
bash -n godaddy-cname.sh
bash -n lib/json.sh
bash -n lib/api.sh
bash -n lib/ui.sh
bash -n lib/credentials.sh
```

All should exit with no output (success).

### 2. Source each library independently

```bash
source lib/json.sh && echo "json.sh OK"
source lib/api.sh && echo "api.sh OK"
source lib/ui.sh && echo "ui.sh OK"
source lib/credentials.sh && echo "credentials.sh OK"
```

All should print "OK" with no errors.

### 3. Verify function availability

```bash
source lib/json.sh
json_count '[{"name":"test"}]'
# Expected: 1
```

### 4. Smoke test the full script

```bash
./godaddy-cname.sh
```

Navigate through: domain selection → list records → add record → edit record → delete record → quit.
Verify all prompts, colors, alignment, and error messages match the pre-refactor behavior.

### 5. Compare byte-identical output (if pre-refactor version available)

```bash
diff <(bash -n godaddy-cname.sh 2>&1) <(git show HEAD:godaddy-cname.sh | bash -n 2>&1)
```
