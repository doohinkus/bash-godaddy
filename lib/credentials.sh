# Credentials

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
