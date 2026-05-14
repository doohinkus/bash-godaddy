# API helpers

api_get() {
  curl -s -H "$AUTH" -H "Accept: application/json" "$GODADDY_BASE_URL$1"
}

api_patch() {
  curl -s -X PATCH -H "$AUTH" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -d "$2" "$GODADDY_BASE_URL$1"
}

api_put() {
  curl -s -X PUT -H "$AUTH" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -d "$2" "$GODADDY_BASE_URL$1"
}

check_api_error() {
  local response="$1"
  [ -z "$response" ] && return 0
  if [ "${response:0:1}" = "{" ] && echo "$response" | grep -q '"message"'; then
    local msg
    if command -v jq &>/dev/null; then
      msg=$(echo "$response" | jq -r '"\(.code // "?") - \(.message)"')
    else
      msg=$(echo "$response" | grep -o '"message":"[^"]*"' | sed 's/"message":"//;s/"//g')
    fi
    echo -e "${R}API Error${NC}: $msg" >&2
    return 1
  fi
  return 0
}
