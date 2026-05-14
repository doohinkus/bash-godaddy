#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# godaddy-cname.sh - Manage GoDaddy CNAME DNS Records
# ============================================================
# Environment:  GODADDY_API_KEY, GODADDY_API_SECRET, GODADDY_BASE_URL
# Profiles:     profiles/<name>.env for multi-account support
# Dependencies: bash 3+, curl
# Optional:     jq (preferred for JSON parsing)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  source "$SCRIPT_DIR/.env"
  set +a
fi

source "$SCRIPT_DIR/lib/json.sh"
source "$SCRIPT_DIR/lib/api.sh"
source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/credentials.sh"

: "${GODADDY_API_KEY:=}"
: "${GODADDY_API_SECRET:=}"
: "${GODADDY_BASE_URL:=https://api.godaddy.com}"

ACTIVE_PROFILE=""
if [ -d "profiles" ]; then
  ACTIVE_PROFILE=$(select_profile)
  if [ -n "$ACTIVE_PROFILE" ]; then
    apply_profile "$ACTIVE_PROFILE"
  fi
fi

AUTH="Authorization: sso-key $GODADDY_API_KEY:$GODADDY_API_SECRET"

RECORD_TYPE="CNAME"

cleanup() { rm -f /tmp/godaddy_*_$$; printf "${NC}"; }
trap cleanup EXIT INT TERM

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
  print_header "Select a Domain" "$ACTIVE_PROFILE"
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
    print_header "${RECORD_TYPE} Records: $domain" "$ACTIVE_PROFILE"

    echo -e "${C}Fetching records...${NC}" >&2
    local response
    response=$(api_get "/v1/domains/$domain/records/$RECORD_TYPE")
    check_api_error "$response" || { pause; return 2; }

    local count
    count=$(json_count "$response")
    echo "$response" >"/tmp/godaddy_records_${domain}_$$"

    if [ "$count" -eq 0 ]; then
      echo -e "${Y}No ${RECORD_TYPE} records found.${NC}"
    else
      printf "${BO}%-4s %-22s %-42s %-6s${NC}\n" "#" "Name" "Data" "TTL"
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
    echo -e "  ${G}[t]${NC} Type    ${G}[r]${NC} Refresh ${G}[b]${NC} Back    ${G}[q]${NC} Quit"
    echo
    echo -n "Choice: "
    read -r action

    case "$action" in
      [aA]) add_record "$domain" ;;
      [eE]) edit_record "$domain" ;;
      [dD]) delete_record "$domain" ;;
      [tT]) RECORD_TYPE=$([ "$RECORD_TYPE" = "CNAME" ] && echo "TXT" || echo "CNAME") ;;
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
  print_header "Add ${RECORD_TYPE} Record" "$ACTIVE_PROFILE"

  echo -n "Subdomain (e.g., www): "
  read -r name
  [ -z "$name" ] && { echo -e "${R}Name is required${NC}" >&2; pause; return 1; }

  echo -n "Value: "
  read -r data
  [ -z "$data" ] && { echo -e "${R}Value is required${NC}" >&2; pause; return 1; }

  echo -n "TTL [3600] (min 600): "
  read -r ttl
  ttl="${ttl:-3600}"
  [ "$ttl" -lt 600 ] 2>/dev/null && ttl=600

  local payload
  payload=$(json_record "$name" "$data" "$ttl" "$RECORD_TYPE")
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
  print_header "Edit ${RECORD_TYPE} Record" "$ACTIVE_PROFILE"

  printf "${BO}%-4s %-22s %-42s %-6s${NC}\n" "#" "Name" "Data" "TTL"
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

  echo -n "Value [$old_data]: "
  read -r data
  data="${data:-$old_data}"

  echo -n "TTL [$old_ttl]: "
  read -r ttl
  ttl="${ttl:-$old_ttl}"
  [ "$ttl" -lt 600 ] 2>/dev/null && ttl=600

  local payload
  payload=$(json_record "$name" "$data" "$ttl" "$RECORD_TYPE")
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
  print_header "Delete ${RECORD_TYPE} Record" "$ACTIVE_PROFILE"

  printf "${BO}%-4s %-22s %-42s %-6s${NC}\n" "#" "Name" "Data" "TTL"
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
  all_records=$(api_get "/v1/domains/$domain/records/$RECORD_TYPE")
  check_api_error "$all_records" || { pause; return 1; }

  filtered_records=$(json_filter_out "$all_records" "$name" "$RECORD_TYPE")

  local resp
  resp=$(api_put "/v1/domains/$domain/records/$RECORD_TYPE" "$filtered_records")

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
  print_header "GoDaddy CNAME Manager" "$ACTIVE_PROFILE"
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
