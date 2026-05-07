#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# godaddy-cname.sh - Manage GoDaddy CNAME DNS Records
# ============================================================
# Environment:  GODADDY_API_KEY, GODADDY_API_SECRET, GODADDY_BASE_URL
# Dependencies: bash 3+, curl
# Optional:     jq (preferred for JSON parsing)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  source "$SCRIPT_DIR/.env"
  set +a
fi

: "${GODADDY_API_KEY:=}"
: "${GODADDY_API_SECRET:=}"
: "${GODADDY_BASE_URL:=https://api.godaddy.com}"

AUTH="Authorization: sso-key $GODADDY_API_KEY:$GODADDY_API_SECRET"

R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'
B='\033[0;34m'; P='\033[0;35m'; C='\033[0;36m'
GR='\033[0;90m'; BO='\033[1m'; NC='\033[0m'

cleanup() { rm -f /tmp/godaddy_*_$$; printf "${NC}"; }
trap cleanup EXIT INT TERM

# ============================================================
# API helpers
# ============================================================

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

# ============================================================
# JSON helpers (jq preferred, grep/sed fallback)
# ============================================================

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

# ============================================================
# Error handling
# ============================================================

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

# ============================================================
# UI helpers
# ============================================================

clear_screen() {
  printf "\033[2J\033[H"
}

print_header() {
  local title="$1"
  echo
  echo -e "${BO}${P}=== $title ===${NC}"
  echo
}

pause() {
  echo
  echo -e "${GR}Press Enter to continue...${NC}"
  read -r
}

confirm() {
  local prompt="$1" yn
  while true; do
    echo -n -e "${Y}$prompt${NC} [y/N] "
    read -r yn
    [ -z "$yn" ] && yn="n"
    case "$yn" in
      [yY]) return 0 ;;
      [nN]) return 1 ;;
      *) echo -e "${R}Please answer y or n${NC}" >&2 ;;
    esac
  done
}

# ============================================================
# Credentials
# ============================================================

check_credentials() {
  if [ -z "$GODADDY_API_KEY" ] || [ -z "$GODADDY_API_SECRET" ]; then
    clear_screen
    print_header "GoDaddy API Credentials"
    echo -e "${Y}Credentials not found in environment or .env file.${NC}"
    echo
    echo -n "API Key: "
    read -r GODADDY_API_KEY
    echo -n "API Secret: "
    read -r -s GODADDY_API_SECRET
    echo
    AUTH="Authorization: sso-key $GODADDY_API_KEY:$GODADDY_API_SECRET"
    echo
  fi

  if [ -z "$GODADDY_API_KEY" ] || [ -z "$GODADDY_API_SECRET" ]; then
    echo -e "${R}API credentials are required.${NC}" >&2
    return 1
  fi
}

# ============================================================
# Domain selection
# ============================================================

fetch_domains() {
  echo -e "${C}Fetching domains...${NC}" >&2
  local response
  response=$(api_get "/v1/domains")
  check_api_error "$response" || return 2

  local domains=()
  if command -v jq &>/dev/null; then
    while IFS= read -r d; do
      domains+=("$d")
    done < <(echo "$response" | jq -r '.[].domain')
  else
    while IFS= read -r d; do
      [ -z "$d" ] && continue
      domains+=("$d")
    done < <(echo "$response" | grep -o '"domain":"[^"]*"' | sed 's/"domain":"//;s/"//g')
  fi

  if [ ${#domains[@]} -eq 0 ]; then
    echo -e "${R}No domains found in your account.${NC}" >&2
    return 2
  fi

  printf '%s\n' "${domains[@]}" >"/tmp/godaddy_domains_$$"

  clear_screen
  print_header "Select a Domain"
  PS3="Enter choice [1-${#domains[@]}]: "
  select domain in "${domains[@]}" "Quit"; do
    if [ -z "$domain" ]; then
      echo -e "${R}Invalid selection${NC}" >&2
    elif [ "$domain" = "Quit" ]; then
      return 1
    else
      manage_records "$domain"
    fi
  done
}

# ============================================================
# Record management (main loop for a domain)
# ============================================================

manage_records() {
  local domain="$1"

  while true; do
    clear_screen
    print_header "CNAME Records: $domain"

    echo -e "${C}Fetching records...${NC}" >&2
    local response
    response=$(api_get "/v1/domains/$domain/records/CNAME")
    check_api_error "$response" || { pause; return 2; }

    local count
    count=$(json_count "$response")
    echo "$response" >"/tmp/godaddy_records_${domain}_$$"

    if [ "$count" -eq 0 ]; then
      echo -e "${Y}No CNAME records found.${NC}"
    else
      printf "${BO}%-4s %-22s %-42s %-6s${NC}\n" "#" "Name" "Target" "TTL"
      printf "${GR}%-74s${NC}\n" "──────────────────────────────────────────────────────────"
      for ((i = 0; i < count; i++)); do
        local name data ttl
        name=$(json_field_at "$response" "name" "$i")
        data=$(json_field_at "$response" "data" "$i")
        ttl=$(json_field_at "$response" "ttl" "$i")
        [ "$ttl" = "0" ] || [ -z "$ttl" ] && ttl=3600
        printf "%-4d %-22s %-42s %-6s\n" $((i + 1)) "$name" "$data" "$ttl"
      done
    fi

    echo
    echo -e "${BO}Actions:${NC}"
    echo -e "  ${G}[a]${NC} Add     ${G}[e]${NC} Edit    ${G}[d]${NC} Delete"
    echo -e "  ${G}[r]${NC} Refresh ${G}[b]${NC} Back    ${G}[q]${NC} Quit"
    echo
    echo -n "Choice: "
    read -r action

    case "$action" in
      [aA]) add_record "$domain" ;;
      [eE]) edit_record "$domain" ;;
      [dD]) delete_record "$domain" ;;
      [rR]) ;;
      [bB]) return 0 ;;
      [qQ]) echo -e "${GR}Goodbye!${NC}"; exit 0 ;;
      *) echo -e "${R}Invalid choice${NC}" >&2; pause ;;
    esac
  done
}

# ============================================================
# Add record
# ============================================================

add_record() {
  local domain="$1"
  clear_screen
  print_header "Add CNAME Record"

  echo -n "Subdomain (e.g., www): "
  read -r name
  [ -z "$name" ] && { echo -e "${R}Name is required${NC}" >&2; pause; return 1; }

  echo -n "Target (e.g., example.github.io): "
  read -r data
  [ -z "$data" ] && { echo -e "${R}Target is required${NC}" >&2; pause; return 1; }

  echo -n "TTL [3600] (min 600): "
  read -r ttl
  ttl="${ttl:-3600}"
  [ "$ttl" -lt 600 ] 2>/dev/null && ttl=600

  local payload
  payload=$(json_record "$name" "$data" "$ttl")
  payload="[$payload]"

  echo -e "${C}Adding record...${NC}" >&2
  local response
  response=$(api_patch "/v1/domains/$domain/records" "$payload")

  if [ -z "$response" ]; then
    echo -e "${G}Record added successfully${NC}"
  else
    check_api_error "$response" && echo -e "${G}Record added successfully${NC}" || true
  fi
  pause
}

# ============================================================
# Edit record
# ============================================================

edit_record() {
  local domain="$1"
  local records_file="/tmp/godaddy_records_${domain}_$$"

  [ ! -f "$records_file" ] && { echo -e "${R}No records data. Refresh first.${NC}" >&2; pause; return 1; }

  local response count
  response=$(cat "$records_file")
  count=$(json_count "$response")
  [ "$count" -eq 0 ] && { echo -e "${R}No records to edit${NC}" >&2; pause; return 1; }

  clear_screen
  print_header "Edit CNAME Record"

  printf "${BO}%-4s %-22s %-42s %-6s${NC}\n" "#" "Name" "Target" "TTL"
  printf "${GR}%-74s${NC}\n" "──────────────────────────────────────────────────────────"
  for ((i = 0; i < count; i++)); do
    local ename edata ettl
    ename=$(json_field_at "$response" "name" "$i")
    edata=$(json_field_at "$response" "data" "$i")
    ettl=$(json_field_at "$response" "ttl" "$i")
    [ "$ettl" = "0" ] || [ -z "$ettl" ] && ettl=3600
    printf "%-4d %-22s %-42s %-6s\n" $((i + 1)) "$ename" "$edata" "$ettl"
  done
  echo

  echo -n "Record number to edit [1-$count]: "
  read -r idx
  idx="${idx:-1}"
  [ "$idx" -lt 1 ] || [ "$idx" -gt "$count" ] 2>/dev/null && { echo -e "${R}Invalid record number${NC}" >&2; pause; return 1; }

  local old_name old_data old_ttl
  old_name=$(json_field_at "$response" "name" $((idx - 1)))
  old_data=$(json_field_at "$response" "data" $((idx - 1)))
  old_ttl=$(json_field_at "$response" "ttl" $((idx - 1)))
  [ "$old_ttl" = "0" ] || [ -z "$old_ttl" ] && old_ttl=3600

  echo
  echo -e "Editing: ${BO}$old_name${NC} → ${BO}$old_data${NC} (TTL: $old_ttl)"
  echo -e "${GR}(Press Enter to keep current value)${NC}"
  echo

  echo -n "Subdomain [$old_name]: "
  read -r name
  name="${name:-$old_name}"

  echo -n "Target [$old_data]: "
  read -r data
  data="${data:-$old_data}"

  echo -n "TTL [$old_ttl]: "
  read -r ttl
  ttl="${ttl:-$old_ttl}"
  [ "$ttl" -lt 600 ] 2>/dev/null && ttl=600

  local payload
  payload=$(json_record "$name" "$data" "$ttl")
  payload="[$payload]"

  echo -e "${C}Updating record...${NC}" >&2
  local resp
  resp=$(api_patch "/v1/domains/$domain/records" "$payload")

  if [ -z "$resp" ]; then
    echo -e "${G}Record updated successfully${NC}"
  else
    check_api_error "$resp" && echo -e "${G}Record updated successfully${NC}" || true
  fi
  pause
}

# ============================================================
# Delete record
# ============================================================

delete_record() {
  local domain="$1"
  local records_file="/tmp/godaddy_records_${domain}_$$"

  [ ! -f "$records_file" ] && { echo -e "${R}No records data. Refresh first.${NC}" >&2; pause; return 1; }

  local response count
  response=$(cat "$records_file")
  count=$(json_count "$response")
  [ "$count" -eq 0 ] && { echo -e "${R}No records to delete${NC}" >&2; pause; return 1; }

  clear_screen
  print_header "Delete CNAME Record"

  printf "${BO}%-4s %-22s %-42s %-6s${NC}\n" "#" "Name" "Target" "TTL"
  printf "${GR}%-74s${NC}\n" "──────────────────────────────────────────────────────────"
  for ((i = 0; i < count; i++)); do
    local dname ddata dttl
    dname=$(json_field_at "$response" "name" "$i")
    ddata=$(json_field_at "$response" "data" "$i")
    dttl=$(json_field_at "$response" "ttl" "$i")
    [ "$dttl" = "0" ] || [ -z "$dttl" ] && dttl=3600
    printf "%-4d %-22s %-42s %-6s\n" $((i + 1)) "$dname" "$ddata" "$dttl"
  done
  echo

  echo -n "Record number to delete [1-$count]: "
  read -r idx
  idx="${idx:-1}"
  [ "$idx" -lt 1 ] || [ "$idx" -gt "$count" ] 2>/dev/null && { echo -e "${R}Invalid record number${NC}" >&2; pause; return 1; }

  local name data ttl
  name=$(json_field_at "$response" "name" $((idx - 1)))
  data=$(json_field_at "$response" "data" $((idx - 1)))
  ttl=$(json_field_at "$response" "ttl" $((idx - 1)))
  [ "$ttl" = "0" ] || [ -z "$ttl" ] && ttl=3600

  echo
  echo -e "Record: ${BO}$name${NC} → ${BO}$data${NC} (TTL: $ttl)"
  echo
  confirm "Delete this record?" || { echo -e "${GR}Cancelled.${NC}"; pause; return 0; }

  echo -e "${C}Deleting record...${NC}" >&2
  local all_records filtered_records
  all_records=$(api_get "/v1/domains/$domain/records/CNAME")
  check_api_error "$all_records" || { pause; return 1; }

  filtered_records=$(json_filter_out "$all_records" "$name")

  local resp
  resp=$(api_put "/v1/domains/$domain/records/CNAME" "$filtered_records")

  if [ -z "$resp" ]; then
    echo -e "${G}Record deleted successfully${NC}"
  else
    check_api_error "$resp" && echo -e "${G}Record deleted successfully${NC}" || true
  fi
  pause
}

# ============================================================
# Main
# ============================================================

main() {
  clear_screen
  print_header "GoDaddy CNAME Manager"
  echo -e "Base URL: ${GR}$GODADDY_BASE_URL${NC}"
  echo

  check_credentials || exit 1

  while true; do
    fetch_domains
    local rc=$?
    if [ "$rc" -eq 1 ]; then
      break
    fi
    if [ "$rc" -eq 2 ]; then
      echo -e "${R}Failed to fetch domains.${NC}" >&2
      confirm "Retry?" || break
    fi
  done

  echo -e "${GR}Goodbye!${NC}"
}

main "$@"
