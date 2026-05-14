# UI helpers

R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'
B='\033[0;34m'; P='\033[0;35m'; C='\033[0;36m'
GR='\033[0;90m'; BO='\033[1m'; NC='\033[0m'

clear_screen() {
  printf "\033[2J\033[H"
}

print_header() {
  local title="$1"
  local profile="${2:-}"
  echo
  if [ -n "$profile" ]; then
    echo -e "${BO}${P}=== $title [$profile] ===${NC}"
  else
    echo -e "${BO}${P}=== $title ===${NC}"
  fi
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
