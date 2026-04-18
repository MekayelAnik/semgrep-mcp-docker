#!/usr/bin/env bash
# Standard colors mapped to 8-bit equivalents
ORANGE='\033[38;5;208m'
BLUE='\033[38;5;12m'
ERROR_RED='\033[38;5;9m'
GREEN='\033[38;5;2m'
SEMGREP_PURPLE='\033[38;5;129m'
ASH_GRAY='\033[38;5;250m'
NC='\033[0m'

# Constants
BUILD_TIMESTAMP=$(cat /usr/local/bin/build-timestamp.txt 2>/dev/null || echo "")

# Function to print separator line
print_separator() {
    printf "\n"
    printf "\n______________________________________________________________________________________________________________________________________________"
    printf "\n"
}

# Print ASCII art
print_ascii_art() {
    printf "${SEMGREP_PURPLE}   /SSSSSS                                                                      /SSSSSS  /SSSSSSS  /SSSSSS        ${NC}\n"
    printf "${SEMGREP_PURPLE}  /SS__  SS                                                                    /SS__  SS| SS__  SS|_  SS_/        ${NC}\n"
    printf "${SEMGREP_PURPLE} | SS  \__/  /SSSSSS  /SSSSSSSS /SSSSSSS   /SSSSSSS /SSSSSSS   /SSSSSSS       | SS  \ SS| SS  \ SS  | SS          ${NC}\n"
    printf "${SEMGREP_PURPLE} |  SSSSSS  /SS__  SS|____ /SS//SS_____/  /SS_____//SS_____/  /SS__  SS       | SSSSSSSS| SSSSSSS/  | SS          ${NC}\n"
    printf "${SEMGREP_PURPLE}  \____  SS| SSSSSSSS   /SS/ |  SSSSSS   | SS     |  SSSSSS  | SS  \ SS       | SS__  SS| SS____/   | SS          ${NC}\n"
    printf "${SEMGREP_PURPLE}  /SS  \ SS| SS_____/  /SS/   \____  SS  | SS      \____  SS | SS  | SS       | SS  | SS| SS        | SS          ${NC}\n"
    printf "${SEMGREP_PURPLE} |  SSSSSS/|  SSSSSSS /SSSSSSSS/SSSSSSS/ |  SSSSSSS/SSSSSSS/ |  SSSSSSS       | SS  | SS| SS       /SSSSSS        ${NC}\n"
    printf "${SEMGREP_PURPLE}  \______/  \_______/|________/_______/   \_______/_______/   \_______/       |__/  |__/|__/      |______/        ${NC}\n"
    printf "\n"
    printf "${GREEN}                 /SSSSSS  /SSSSSSSS /SSSSSSS  /SS    /SS /SSSSSSSS /SSSSSSS                                     ${NC}\n"
    printf "${GREEN}                /SS__  SS| SS_____/| SS__  SS| SS   | SS| SS_____/| SS__  SS                                    ${NC}\n"
    printf "${GREEN}               | SS  \__/| SS      | SS  \ SS| SS   | SS| SS      | SS  \ SS                                    ${NC}\n"
    printf "${GREEN}               |  SSSSSS | SSSSS   | SSSSSSS/|  SS / SS/| SSSSS   | SSSSSSS/                                    ${NC}\n"
    printf "${GREEN}                \____  SS| SS__/   | SS__  SS \  SS SS/ | SS__/   | SS__  SS                                    ${NC}\n"
    printf "${GREEN}                /SS  \ SS| SS      | SS  \ SS  \  SSS/  | SS      | SS  \ SS                                    ${NC}\n"
    printf "${GREEN}               |  SSSSSS/| SSSSSSSS| SS  | SS   \  S/   | SSSSSSSS| SS  | SS                                    ${NC}\n"
    printf "${GREEN}                \______/ |________/|__/  |__/    \_/    |________/|__/  |__/                                    ${NC}\n"
    printf "\n"
}

# Print Maintainer information
print_maintainer_info() {
    printf "\n"
    printf "${ASH_GRAY} ███╗   ███╗██████╗        ███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗   ██╗███████╗██╗          █████╗ ███╗   ██╗██╗██╗  ██╗                 ${NC}\n"
    printf "${ASH_GRAY} ████╗ ████║██╔══██╗       ████╗ ████║██╔════╝██║ ██╔╝██╔══██╗╚██╗ ██╔╝██╔════╝██║         ██╔══██╗████╗  ██║██║██║ ██╔╝                 ${NC}\n"
    printf "${ASH_GRAY} ██╔████╔██║██║  ██║       ██╔████╔██║█████╗  █████╔╝ ███████║ ╚████╔╝ █████╗  ██║         ███████║██╔██╗ ██║██║█████╔╝                  ${NC}\n"
    printf "${ASH_GRAY} ██║╚██╔╝██║██║  ██║       ██║╚██╔╝██║██╔══╝  ██╔═██╗ ██╔══██║  ╚██╔╝  ██╔══╝  ██║         ██╔══██║██║╚██╗██║██║██╔═██╗                  ${NC}\n"
    printf "${ASH_GRAY} ██║ ╚═╝ ██║██████╔╝██╗    ██║ ╚═╝ ██║███████╗██║  ██╗██║  ██║   ██║   ███████╗███████╗    ██║  ██║██║ ╚████║██║██║  ██╗                 ${NC}\n"
    printf "${ASH_GRAY} ╚═╝     ╚═╝╚═════╝ ╚═╝    ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚══════╝    ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝                 ${NC}\n"
}

# Print system information
print_system_info() {
    print_separator

    local disp_port="$PORT"
    local display_ip=$(ip route 2>/dev/null | awk '/default/ {print $3}' || echo "unknown")
    local port_display=":$disp_port"
    [[ "$disp_port" == '80' ]] && port_display=""

printf "${SEMGREP_PURPLE} >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Starting Semgrep MCP Server! <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< \n${NC}"
printf "${ORANGE} ==================================${NC}\n"
printf "${ORANGE} PUID: %s${NC}\n" "$PUID"
printf "${ORANGE} PGID: %s${NC}\n" "$PGID"
printf "${ORANGE} MCP IP Address: %s\n${NC}" "$display_ip"
printf "${ORANGE} MCP Server PORT: ${GREEN}%s\n${NC}\n" "${disp_port:-80}"
printf "${ORANGE} Semgrep Version: ${GREEN}%s\n${NC}" "${SEMGREP_VERSION:-unknown}"
printf "${ORANGE} Pro Engine Mode: ${GREEN}%s\n${NC}" "${PRO_MODE_DISPLAY:-OSS}"
printf "${ORANGE} ==================================${NC}\n"
printf "${ERROR_RED} Note: You may need to change the IP address to your host machine IP\n${NC}"
[[ -n "$BUILD_TIMESTAMP" && -f "$BUILD_TIMESTAMP" ]] && BUILD_TIMESTAMP=$(cat "$BUILD_TIMESTAMP") && printf "${ORANGE}${BUILD_TIMESTAMP}${NC}\n"
    printf "${BLUE}This Container was started on:${NC} ${GREEN}$(date)${NC}\n"
}

# Main execution
main() {
    print_separator
    print_ascii_art
    print_maintainer_info
    print_system_info
}

main
