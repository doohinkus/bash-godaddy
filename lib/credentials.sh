# Credentials
#
# Functions:
#   check_credentials         — Interactive prompt fallback (existing)
#   load_profiles             — Scan profiles/*.env for valid credential files
#   select_profile            — Show TUI menu or auto-select; returns profile name or ""
#   apply_profile <name>      — Source profile file, rebuild AUTH, set ACTIVE_PROFILE

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

# -------------------------------------------------------
# Multi-profile credential support
# -------------------------------------------------------

load_profiles() {
  _PROFILES=""
  _PROFILE_COUNT=0
  [ ! -d "profiles" ] && return
  for f in "profiles/"*.env; do
    [ ! -f "$f" ] && continue
    local name
    name=$(basename "$f" .env)
    if (
      set -a
      source "$f" 2>/dev/null
      set +a
      [ -n "${GODADDY_API_KEY:-}" ] && [ -n "${GODADDY_API_SECRET:-}" ]
    ); then
      _PROFILES="${_PROFILES}${name}"$'\n'
      _PROFILE_COUNT=$((_PROFILE_COUNT + 1))
    else
      echo -e "${Y}Warning: skipping invalid profile '$name' (missing or empty credentials)${NC}" >&2
    fi
  done
}

select_profile() {
  load_profiles
  case $_PROFILE_COUNT in
    0) echo "" ;;
    1) printf "%s" "$_PROFILES" ;;
    *)
      local names=()
      while IFS= read -r p; do
        [ -n "$p" ] && names+=("$p")
      done <<< "$_PROFILES"

      clear_screen
      echo -e "${BO}${P}=== Select Profile ===${NC}"
      echo
      PS3="Enter choice [1-${#names[@]}]: "
      select profile in "${names[@]}"; do
        if [ -n "$profile" ]; then
          echo "$profile"
          return
        fi
        echo -e "${R}Invalid selection${NC}" >&2
      done
      ;;
  esac
}

apply_profile() {
  local name="$1"
  . "profiles/${name}.env"
  : "${GODADDY_BASE_URL:=https://api.godaddy.com}"
  AUTH="Authorization: sso-key $GODADDY_API_KEY:$GODADDY_API_SECRET"
  ACTIVE_PROFILE="$name"
}
