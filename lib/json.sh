# JSON helpers (jq preferred, grep/sed fallback)

json_fields() {
  local json="$1" field="$2"
  if command -v jq &>/dev/null; then
    echo "$json" | jq -r ".[].$field"
  else
    echo "$json" | grep -o "\"$field\":\"[^\"]*\"" | sed "s/\"$field\":\"//;s/\"//g"
  fi
}

json_field_at() {
  local json="$1" field="$2" idx="$3"
  if command -v jq &>/dev/null; then
    echo "$json" | jq -r ".[$idx].$field"
  else
    json_fields "$json" "$field" | sed -n "$((idx+1))p"
  fi
}

json_record() {
  local name="$1" data="$2" ttl="$3"
  printf '{"name":"%s","data":"%s","ttl":%d,"type":"CNAME"}' "$name" "$data" "$ttl"
}

json_filter_out() {
  local json="$1" exclude_name="$2"
  if command -v jq &>/dev/null; then
    echo "$json" | jq -c "map(select(.name != \"$exclude_name\"))"
  else
    local count new_json first=true
    count=$(echo "$json" | grep -c '"name"' 2>/dev/null || echo 0)
    new_json=""
    first=true
    for ((i = 0; i < count; i++)); do
      local n d t
      n=$(json_field_at "$json" "name" "$i")
      d=$(json_field_at "$json" "data" "$i")
      t=$(json_field_at "$json" "ttl" "$i")
      [ "$t" = "0" ] || [ -z "$t" ] && t=3600
      [ "$n" = "$exclude_name" ] && continue
      if $first; then
        new_json=$(json_record "$n" "$d" "$t")
        first=false
      else
        new_json="$new_json,$(json_record "$n" "$d" "$t")"
      fi
    done
    echo "[$new_json]"
  fi
}

json_count() {
  local json="$1"
  if command -v jq &>/dev/null; then
    echo "$json" | jq length
  else
    echo "$json" | grep -c '"name"' 2>/dev/null || echo 0
  fi
}
