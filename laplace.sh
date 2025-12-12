#!/usr/bin/env bash

#########################################################
# LAPLACE – the unified command nexus
# A blue-themed, extensible CLI hub for security tools
#########################################################

# ------------ global paths -------------

TOOLS_CONFIG_FILE="${HOME}/.laplace_tools.conf"
SETTINGS_FILE="${HOME}/.laplace_settings"

# ------------------------------------------------------------
# Identity / Repository
# ------------------------------------------------------------
GITHUB_USER="vireline"
DISCORD_USER="vireline"
GITHUB_REPO_URL="https://github.com/vireline/laplace-nexus-cli"

# Versioning
LAPLACE_VERSION="0.3.1"

# Script directory (needed for update system)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Plugins directory (The CLI automatically discovers and loads all .plugin files in this directory)
PLUGINS_DIR="${SCRIPT_DIR}/plugins"

# ------------ colours & themes ----------

RESET="\e[0m"
BOLD="\e[1m"

ACCENT1=""   # main accent
ACCENT2=""   # secondary accent
ACCENT3=""   # tertiary accent
MUTED=""     # muted text

THEME="blue"
AUTO_INSTALL=0
PASSWORD_HASH=""

apply_theme() {
    case "$THEME" in
        violet)
            ACCENT1="\e[38;5;135m"
            ACCENT2="\e[38;5;177m"
            ACCENT3="\e[38;5;141m"
            MUTED="\e[38;5;244m"
            ;;
        mono)
            ACCENT1="\e[38;5;250m"
            ACCENT2="\e[38;5;252m"
            ACCENT3="\e[38;5;246m"
            MUTED="\e[38;5;243m"
            ;;
        *)
            THEME="blue"
            ACCENT1="\e[38;5;39m"
            ACCENT2="\e[38;5;81m"
            ACCENT3="\e[38;5;45m"
            MUTED="\e[38;5;245m"
            ;;
    esac
}

# ------------ settings handling ----------

init_settings() {
    if [ ! -f "$SETTINGS_FILE" ]; then
        cat > "$SETTINGS_FILE" <<EOF
THEME=blue
AUTO_INSTALL=0
PASSWORD_HASH=
EOF
    fi
}

load_settings() {
    init_settings
    # shellcheck source=/dev/null
    . "$SETTINGS_FILE"

    # ensure globals updated
    THEME="${THEME:-blue}"
    AUTO_INSTALL="${AUTO_INSTALL:-0}"
    PASSWORD_HASH="${PASSWORD_HASH:-}"
    apply_theme
}

save_settings() {
    cat > "$SETTINGS_FILE" <<EOF
THEME=$THEME
AUTO_INSTALL=$AUTO_INSTALL
PASSWORD_HASH=$PASSWORD_HASH
EOF
}

# ------------ beeps & helpers ------------

beep() {
    echo -ne "\a"
}

pause() {
    echo
    read -rp "Press Enter to continue ▸ " _
}

header() {
    clear
    echo -e "${ACCENT2}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
    echo -e "${ACCENT2}${BOLD}║                     LAPLACE                      ║${RESET}"
    echo -e "${ACCENT2}${BOLD}║             the unified command nexus            ║${RESET}"
    echo -e "${ACCENT2}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
    echo
}

startup_animation() {
    clear
    for step in 1 2 3; do
        echo -e "${ACCENT2}${BOLD}Initialising Laplace layer ${step}/3 ...${RESET}"
        beep
        sleep 0.25
        clear
    done
    header
}

check_installed() {
    local tool="$1"
    if command -v "$tool" &>/dev/null; then
        echo -e "${ACCENT2}[✔]${RESET} ${tool} is installed."
        return 0
    else
        echo -e "${ACCENT1}[✖]${RESET} ${tool} is NOT installed."
        return 1
    fi
}

# map tool -> apt package (fallback to tool name)
apt_package_for_tool() {
    local t="$1"
    case "$t" in
        burpsuite) echo "burpsuite" ;;
        sqlmap) echo "sqlmap" ;;
        ffuf) echo "ffuf" ;;
        gobuster) echo "gobuster" ;;
        nuclei) echo "nuclei" ;;
        nmap) echo "nmap" ;;
        masscan) echo "masscan" ;;
        netdiscover) echo "netdiscover" ;;
        mitmproxy) echo "mitmproxy" ;;
        airodump-ng|aircrack-ng|wifite) echo "aircrack-ng" ;; # wifite often separate, but leave
        theHarvester) echo "theharvester" ;;
        spiderfoot) echo "spiderfoot" ;;
        sherlock) echo "sherlock" ;;
        exiftool) echo "exiftool" ;;
        msfconsole) echo "metasploit-framework" ;;
        searchsploit) echo "exploitdb" ;;
        ncat) echo "ncat" ;;
        hashcat) echo "hashcat" ;;
        john) echo "john" ;;
        hydra) echo "hydra" ;;
        hashid) echo "hashid" ;;
        autopsy) echo "autopsy" ;;
        volatility) echo "volatility" ;;
        binwalk) echo "binwalk" ;;
        yara) echo "yara" ;;
        ghidra) echo "ghidra" ;;
        r2|radare2) echo "radare2" ;;
        cutter) echo "cutter" ;;
        strings) echo "binutils" ;;
        wireshark) echo "wireshark" ;;
        tshark) echo "tshark" ;;
        suricata) echo "suricata" ;;
        zeek) echo "zeek" ;;
        *) echo "$t" ;;
    esac
}

install_tool() {
    local tool="$1"
    local pkg
    pkg="$(apt_package_for_tool "$tool")"

    echo
    echo -e "${MUTED}Attempting to install ${tool} (package: ${pkg})${RESET}"
    echo -e "${MUTED}You may be asked for your sudo password.${RESET}"
    echo
    sudo apt update && sudo apt install -y "$pkg"
    if command -v "$tool" &>/dev/null; then
        echo -e "${ACCENT2}[✔]${RESET} ${tool} installed successfully."
    else
        echo -e "${ACCENT1}[!]${RESET} ${tool} still not found. Check package name."
    fi
    pause
}

ensure_tool_available() {
    local tool="$1"
    if command -v "$tool" &>/dev/null; then
        return 0
    fi

    echo
    echo -e "${ACCENT1}[!]${RESET} ${tool} is not installed."
    if [ "$AUTO_INSTALL" -eq 1 ]; then
        echo -e "${MUTED}Auto-install is enabled. Installing...${RESET}"
        install_tool "$tool"
    else
        read -rp "Install ${tool} now via apt? [y/N] " ans
        case "$ans" in
            y|Y) install_tool "$tool" ;;
            *) echo "Skipping install."; pause ;;
        esac
    fi

    command -v "$tool" &>/dev/null
}

run_tool_now() {
    local tool="$1"
    if ! ensure_tool_available "$tool"; then
        return
    fi
    echo
    read -rp "Extra arguments for ${tool} (empty = none): " args
    echo
    echo -e "${MUTED}Running: ${tool} ${args}${RESET}"
    echo "----------------------------------------"
    bash -c "${tool} ${args}"
    echo
    echo "----------------------------------------"
    pause
}

tool_menu() {
    local tool="$1"
    local desc="$2"
    local example="$3"

    while true; do
        header
        echo -e "${ACCENT3}${BOLD}▌ ${tool}${RESET}"
        echo
        echo -e "${MUTED}${desc}${RESET}"
        echo
        check_installed "$tool"
        echo
        echo -e "${ACCENT3}1)${RESET} Show ${tool} --help"
        echo -e "${ACCENT3}2)${RESET} Open man page (if available)"
        echo -e "${ACCENT3}3)${RESET} Show example usage"
        echo -e "${ACCENT3}4)${RESET} Run ${tool} now"
        echo -e "${ACCENT3}5)${RESET} Install / repair this tool"
        echo -e "${ACCENT3}0)${RESET} Back"
        echo
        read -rp "Select ▸ " choice

        case "$choice" in
            1)
                if ensure_tool_available "$tool"; then
                    "$tool" --help | less
                fi
                ;;
            2)
                if man "$tool" &>/dev/null; then
                    man "$tool"
                else
                    echo
                    echo "[!] No man page for ${tool}."
                    pause
                fi
                ;;
            3)
                header
                echo -e "${ACCENT3}${BOLD}Example – ${tool}${RESET}"
                echo
                echo -e "${MUTED}${example}${RESET}"
                echo
                pause
                ;;
            4)
                run_tool_now "$tool"
                ;;
            5)
                install_tool "$tool"
                ;;
            0)
                break
                ;;
            *)
                echo "Invalid option."
                beep
                pause
                ;;
        esac
    done
}

# ------------ custom tools system --------

declare -gA CT_TOOL CT_DESC CT_EX CT_CAT CT_LINE CT_SRC
CUSTOM_COUNT=0

init_tools_config() {
    [ -f "$TOOLS_CONFIG_FILE" ] || touch "$TOOLS_CONFIG_FILE"
}

load_custom_tools() {
    init_tools_config
    CT_TOOL=()
    CT_DESC=()
    CT_EX=()
    CT_CAT=()
    CT_LINE=()
    CT_SRC=()
    local idx=1
    local lineno=0

    # 1) user custom tools from ~/.laplace_tools.conf (deletable)
    while IFS='|' read -r category tool desc example; do
        lineno=$((lineno+1))
        [ -z "$tool" ] && continue
        CT_CAT[$idx]="$category"
        CT_TOOL[$idx]="$tool"
        CT_DESC[$idx]="$desc"
        CT_EX[$idx]="$example"
        CT_LINE[$idx]=$lineno
        CT_SRC[$idx]="user"
        idx=$((idx+1))
    done < "$TOOLS_CONFIG_FILE"

    # 2) plugin tools from ./plugins/*.plugin (read-only)
    if [ -d "$PLUGINS_DIR" ]; then
        for f in "$PLUGINS_DIR"/*.plugin; do
            [ -e "$f" ] || continue
            while IFS='|' read -r category tool desc example; do
                [ -z "$tool" ] && continue
                CT_CAT[$idx]="$category"
                CT_TOOL[$idx]="$tool"
                CT_DESC[$idx]="$desc"
                CT_EX[$idx]="$example"
                CT_LINE[$idx]=0
                CT_SRC[$idx]="plugin"
                idx=$((idx+1))
            done < "$f"
        done
    fi

    CUSTOM_COUNT=$((idx-1))
}


add_custom_tool() {
    header
    echo -e "${ACCENT3}${BOLD}Add Custom Tool${RESET}"
    echo
    echo -e "${MUTED}This will be stored in ${TOOLS_CONFIG_FILE}${RESET}"
    echo
    read -rp "Category label (e.g. web, wifi, osint): " category
    read -rp "Tool command (what you type to run it): " tool
    read -rp "Short description: " desc
    echo "Example command (what you'd normally type):"
    read -rp "> " example

    if [ -z "$tool" ]; then
        echo
        echo "[!] Tool name cannot be empty."
        pause
        return
    fi

    init_tools_config
    echo "${category}|${tool}|${desc}|${example}" >> "$TOOLS_CONFIG_FILE"
    echo
    echo "Saved."
    pause
}

delete_custom_tool() {
    load_custom_tools
    if [ "$CUSTOM_COUNT" -eq 0 ]; then
        echo
        echo "No custom tools to delete."
        pause
        return
    fi

    header
    echo -e "${ACCENT3}${BOLD}Delete Custom Tool${RESET}"
    echo
    for i in $(seq 1 "$CUSTOM_COUNT"); do
        echo -e "${ACCENT3}${i})${RESET} [${CT_CAT[$i]}] ${CT_TOOL[$i]} – ${CT_DESC[$i]} (${CT_SRC[$i]})"
    done
    echo
    read -rp "Number to remove (0 to cancel): " n

    if [ "$n" = "0" ]; then
        return
    fi

    if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ] || [ "$n" -gt "$CUSTOM_COUNT" ]; then
        echo "Invalid selection."
        pause
        return
    fi

        if [ "${CT_SRC[$n]}" = "plugin" ]; then
        echo
        echo "That entry comes from a plugin file and cannot be deleted here."
        echo "Edit the plugin file in: $PLUGINS_DIR"
        pause
        return
    fi

    local line_to_delete=${CT_LINE[$n]}
    sed -i "${line_to_delete}d" "$TOOLS_CONFIG_FILE"
    echo
    echo "Removed."
    pause
}

menu_custom() {
    while true; do
        load_custom_tools
        header
        echo -e "${ACCENT3}${BOLD}Custom tools (Laplace memory)${RESET}"
        echo

        if [ "$CUSTOM_COUNT" -eq 0 ]; then
            echo -e "${MUTED}No custom tools yet. Add one to begin.${RESET}"
            echo
        else
            for i in $(seq 1 "$CUSTOM_COUNT"); do
                echo -e "${ACCENT3}${i})${RESET} [${CT_CAT[$i]}] ${CT_TOOL[$i]} – ${CT_DESC[$i]}"
            done
            echo
        fi

        echo -e "${ACCENT3}a)${RESET} Add new tool"
        echo -e "${ACCENT3}d)${RESET} Delete a tool"
        echo -e "${ACCENT3}0)${RESET} Back"
        echo
        read -rp "Select ▸ " c

        case "$c" in
            a|A) add_custom_tool ;;
            d|D) delete_custom_tool ;;
            0) break ;;
            *)
                if [[ "$c" =~ ^[0-9]+$ ]] && [ "$c" -ge 1 ] && [ "$c" -le "$CUSTOM_COUNT" ]; then
                    tool_menu "${CT_TOOL[$c]}" "${CT_DESC[$c]}" "${CT_EX[$c]}"
                else
                    echo "Invalid selection."
                    beep
                    pause
                fi
                ;;
        esac
    done
}

# ------------ registry for search --------

declare -a REG_TOOL REG_DESC REG_EX
REG_COUNT=0

register_tool() {
    local t="$1" d="$2" e="$3"
    REG_COUNT=$((REG_COUNT+1))
    REG_TOOL[$REG_COUNT]="$t"
    REG_DESC[$REG_COUNT]="$d"
    REG_EX[$REG_COUNT]="$e"
}

populate_registry() {
    REG_COUNT=0
    register_tool "burpsuite" "Intercepting web proxy." "burpsuite"
    register_tool "sqlmap" "Automated SQL injection." "sqlmap -u 'http://target/page.php?id=1' --batch"
    register_tool "ffuf" "Fast web fuzzer for dirs/params." "ffuf -w wordlist.txt -u http://target/FUZZ"
    register_tool "nuclei" "Template-based vuln scanner." "nuclei -u https://target.com -severity medium,high,critical"
    register_tool "gobuster" "Directory and vhost brute-forcer." "gobuster dir -u http://target -w wordlist.txt"
    register_tool "nmap" "Port & service scanner." "nmap -sC -sV -O target"
    register_tool "masscan" "Ultra-fast port scanner." "masscan -p1-65535 target --rate 10000"
    register_tool "netdiscover" "ARP-based host discovery." "netdiscover -r 192.168.1.0/24"
    register_tool "mitmproxy" "Interactive HTTP/S proxy." "mitmproxy"

    register_tool "airodump-ng" "Capture WiFi handshakes." "airodump-ng wlan0mon"
    register_tool "aircrack-ng" "Crack WPA/WPA2." "aircrack-ng capture.cap -w wordlist.txt"
    register_tool "wifite" "Automated WiFi attacks." "wifite"

    register_tool "theHarvester" "OSINT for emails/subdomains." "theHarvester -d example.com -b all"
    register_tool "spiderfoot" "Automated OSINT web UI." "spiderfoot -l 127.0.0.1:5001"
    register_tool "sherlock" "Username OSINT." "sherlock username_here"
    register_tool "exiftool" "File metadata viewer." "exiftool image.jpg"

    register_tool "msfconsole" "Metasploit framework console." "msfconsole"
    register_tool "searchsploit" "Search exploit-db locally." "searchsploit apache 2.4"
    register_tool "ncat" "Netcat variant for rev shells." "ncat -lvnp 4444"

    register_tool "hashcat" "GPU-based hash cracking." "hashcat -m 0 -a 0 hashes.txt wordlist.txt"
    register_tool "john" "John the Ripper." "john --wordlist=rockyou.txt hashes.txt"
    register_tool "hydra" "Online login bruteforce." "hydra -l admin -P passwords.txt ssh://target"
    register_tool "hashid" "Identify hash type." "hashid '5f4dcc3b5aa765d61d8327deb882cf99'"

    register_tool "autopsy" "GUI forensics suite." "autopsy"
    register_tool "volatility" "Memory forensics." "volatility -f memory.img --info"
    register_tool "binwalk" "Firmware/binary analysis." "binwalk firmware.bin"
    register_tool "yara" "Rule-based malware detection." "yara rules.yar suspicious_file"

    register_tool "ghidra" "Full reverse engineering suite." "ghidra"
    register_tool "r2" "Radare2 core." "r2 binaryfile"
    register_tool "cutter" "GUI over radare2." "cutter"
    register_tool "strings" "Printable strings from binaries." "strings binaryfile | less"

    register_tool "wireshark" "GUI packet analyzer." "wireshark"
    register_tool "tshark" "CLI packet analyzer." "tshark -i eth0"
    register_tool "suricata" "IDS/IPS engine." "suricata -c /etc/suricata/suricata.yaml -i eth0"
    register_tool "zeek" "Network security monitoring." "zeek -i eth0"
}

search_tools() {
    load_custom_tools
    header
    echo -e "${ACCENT3}${BOLD}Search tools${RESET}"
    echo
    read -rp "Search term ▸ " term
    echo

    if [ -z "$term" ]; then
        echo "Empty term."
        pause
        return
    fi

    local lower_term
    lower_term="$(echo "$term" | tr 'A-Z' 'a-z')"

    declare -a RES_TOOL RES_DESC RES_EX
    local RES_COUNT=0

    # builtin registry
    for i in $(seq 1 "$REG_COUNT"); do
        local name="${REG_TOOL[$i]}"
        local desc="${REG_DESC[$i]}"
        local l_name l_desc
        l_name="$(echo "$name" | tr 'A-Z' 'a-z')"
        l_desc="$(echo "$desc" | tr 'A-Z' 'a-z')"
        if [[ "$l_name" == *"$lower_term"* ]] || [[ "$l_desc" == *"$lower_term"* ]]; then
            RES_COUNT=$((RES_COUNT+1))
            RES_TOOL[$RES_COUNT]="$name"
            RES_DESC[$RES_COUNT]="$desc"
            RES_EX[$RES_COUNT]="${REG_EX[$i]}"
        fi
    done

    # custom tools
    for i in $(seq 1 "$CUSTOM_COUNT"); do
        local name="${CT_TOOL[$i]}"
        local desc="${CT_DESC[$i]}"
        local l_name l_desc
        l_name="$(echo "$name" | tr 'A-Z' 'a-z')"
        l_desc="$(echo "$desc" | tr 'A-Z' 'a-z')"
        if [[ "$l_name" == *"$lower_term"* ]] || [[ "$l_desc" == *"$lower_term"* ]]; then
            RES_COUNT=$((RES_COUNT+1))
            RES_TOOL[$RES_COUNT]="$name"
            RES_DESC[$RES_COUNT]="$desc"
            RES_EX[$RES_COUNT]="${CT_EX[$i]}"
        fi
    done

    if [ "$RES_COUNT" -eq 0 ]; then
        echo "No tools matched."
        pause
        return
    fi

    echo -e "${MUTED}Matches:${RESET}"
    echo
    for i in $(seq 1 "$RES_COUNT"); do
        echo -e "${ACCENT3}${i})${RESET} ${RES_TOOL[$i]} – ${RES_DESC[$i]}"
    done
    echo
    read -rp "Open which tool (0 to cancel)? ▸ " pick

    if [ "$pick" = "0" ]; then
        return
    fi

    if ! [[ "$pick" =~ ^[0-9]+$ ]] || [ "$pick" -lt 1 ] || [ "$pick" -gt "$RES_COUNT" ]; then
        echo "Invalid choice."
        pause
        return
    fi

    tool_menu "${RES_TOOL[$pick]}" "${RES_DESC[$pick]}" "${RES_EX[$pick]}"
}

# ------------ password protection --------

prompt_password_if_needed() {
    if [ -z "$PASSWORD_HASH" ]; then
        return
    fi

    for attempt in 1 2 3; do
        header
        echo -e "${MUTED}Laplace is locked. Enter password (attempt ${attempt}/3).${RESET}"
        echo
        read -rsp "Password ▸ " pw
        echo

        local hash
        hash="$(printf '%s' "$pw" | sha256sum | cut -d' ' -f1)"

        if [ "$hash" = "$PASSWORD_HASH" ]; then
            beep
            return
        else
            echo -e "${ACCENT1}Incorrect.${RESET}"
            beep
            sleep 0.7
        fi
    done

    echo -e "${ACCENT1}Too many incorrect attempts. Exiting.${RESET}"
    exit 1
}

settings_menu() {
    while true; do
        header
        echo -e "${ACCENT3}${BOLD}Settings${RESET}"
        echo
        echo -e "${MUTED}Current theme:${RESET} ${THEME}"
        echo -e "${MUTED}Auto-install:${RESET} ${AUTO_INSTALL}"
        if [ -n "$PASSWORD_HASH" ]; then
            echo -e "${MUTED}Password protection:${RESET} enabled"
        else
            echo -e "${MUTED}Password protection:${RESET} disabled"
        fi
        echo
        echo -e "${ACCENT3}1)${RESET} Change theme (blue / violet / mono)"
        echo -e "${ACCENT3}2)${RESET} Toggle auto-install missing tools"
        echo -e "${ACCENT3}3)${RESET} Set / change password"
        echo -e "${ACCENT3}4)${RESET} Disable password protection"
        echo -e "${ACCENT3}0)${RESET} Back"
        echo
        read -rp "Select ▸ " c

        case "$c" in
            1)
                read -rp "Theme (blue/violet/mono) ▸ " t
                case "$t" in
                    blue|violet|mono)
                        THEME="$t"
                        apply_theme
                        save_settings
                        ;;
                    *)
                        echo "Unknown theme."
                        pause
                        ;;
                esac
                ;;
            2)
                if [ "$AUTO_INSTALL" -eq 1 ]; then
                    AUTO_INSTALL=0
                else
                    AUTO_INSTALL=1
                fi
                save_settings
                ;;
            3)
                read -rsp "New password ▸ " p1
                echo
                read -rsp "Repeat password ▸ " p2
                echo
                if [ "$p1" != "$p2" ]; then
                    echo "Passwords do not match."
                    pause
                else
                    PASSWORD_HASH="$(printf '%s' "$p1" | sha256sum | cut -d' ' -f1)"
                    save_settings
                    echo "Password set."
                    pause
                fi
                ;;
            4)
                PASSWORD_HASH=""
                save_settings
                echo "Password protection disabled."
                pause
                ;;
            0)
                break
                ;;
            *)
                echo "Invalid option."
                beep
                pause
                ;;
        esac
    done
}

# ---------- category menus (same as before, just shorter text) ----------

menu_web() {
    while true; do
        header
        echo -e "${ACCENT3}${BOLD}Web (apps & APIs)${RESET}"
        echo
        echo -e "${ACCENT3}1)${RESET} burpsuite   – Intercepting proxy"
        echo -e "${ACCENT3}2)${RESET} sqlmap      – SQL injection automation"
        echo -e "${ACCENT3}3)${RESET} ffuf        – Fuzzer for dirs/params"
        echo -e "${ACCENT3}4)${RESET} gobuster    – Dir/vhost brute force"
        echo -e "${ACCENT3}4)${RESET} nuclei      – Template vuln scanner"
        echo -e "${ACCENT3}0)${RESET} Back"
        echo
        read -rp "Select ▸ " c
        case "$c" in
            1) tool_menu "burpsuite" "Intercept, edit and replay HTTP/S traffic." "burpsuite" ;;
            2) tool_menu "sqlmap" "Automate discovery and exploitation of SQL injection." "sqlmap -u 'http://target/page.php?id=1' --batch" ;;
            3) tool_menu "ffuf" "Brute-force directories or parameters with wordlists." "ffuf -w wordlist.txt -u http://target/FUZZ" ;;
            4) tool_menu "gobuster" "Bruteforce directories or vhosts against a target." "gobuster dir -u http://target -w wordlist.txt" ;;
            5) tool_menu "nuclei" "Run templates to scan for vulnerabilities quickly." "nuclei -u https://target.com -severity medium,high,critical" ;;
            0) break ;;
            *) echo "Invalid option."; beep; pause ;;
        esac
    done
}

menu_network() {
    while true; do
        header
        echo -e "${ACCENT3}${BOLD}Network / Scanning${RESET}"
        echo
        echo -e "${ACCENT3}1)${RESET} nmap        – Port & service scanner"
        echo -e "${ACCENT3}2)${RESET} masscan     – Ultra-fast scanner"
        echo -e "${ACCENT3}3)${RESET} netdiscover – ARP discovery"
        echo -e "${ACCENT3}4)${RESET} mitmproxy   – Interactive HTTP/S proxy"
        echo -e "${ACCENT3}0)${RESET} Back"
        echo
        read -rp "Select ▸ " c
        case "$c" in
            1) tool_menu "nmap" "Scan hosts and discover open ports/services." "nmap -sC -sV -O target" ;;
            2) tool_menu "masscan" "Very fast scanner for huge ranges." "masscan -p1-65535 target --rate 10000" ;;
            3) tool_menu "netdiscover" "Find live hosts on a local network." "netdiscover -r 192.168.1.0/24" ;;
            4) tool_menu "mitmproxy" "Intercept, inspect and modify HTTP/S traffic." "mitmproxy" ;;
            0) break ;;
            *) echo "Invalid option."; beep; pause ;;
        esac
    done
}

menu_wifi() {
    while true; do
        header
        echo -e "${ACCENT3}${BOLD}WiFi / Wireless${RESET}"
        echo
        echo -e "${ACCENT3}1)${RESET} airodump-ng – Capture handshakes"
        echo -e "${ACCENT3}2)${RESET} aircrack-ng – Crack WPA/WPA2"
        echo -e "${ACCENT3}3)${RESET} wifite      – Automated WiFi attacks"
        echo -e "${ACCENT3}0)${RESET} Back"
        echo
        read -rp "Select ▸ " c
        case "$c" in
            1) tool_menu "airodump-ng" "Monitor WiFi networks and capture handshakes." "airodump-ng wlan0mon" ;;
            2) tool_menu "aircrack-ng" "Crack WPA/WPA2 handshakes with wordlists." "aircrack-ng capture.cap -w wordlist.txt" ;;
            3) tool_menu "wifite" "Automated WiFi pentesting wrapper." "wifite" ;;
            0) break ;;
            *) echo "Invalid option."; beep; pause ;;
        esac
    done
}

menu_osint() {
    while true; do
        header
        echo -e "${ACCENT3}${BOLD}OSINT / Recon${RESET}"
        echo
        echo -e "${ACCENT3}1)${RESET} theHarvester – Emails, subdomains"
        echo -e "${ACCENT3}2)${RESET} spiderfoot   – Automated OSINT"
        echo -e "${ACCENT3}3)${RESET} sherlock     – Username enumeration"
        echo -e "${ACCENT3}4)${RESET} exiftool     – File metadata"
        echo -e "${ACCENT3}0)${RESET} Back"
        echo
        read -rp "Select ▸ " c
        case "$c" in
            1) tool_menu "theHarvester" "Collect emails, hosts and subdomains from public sources." "theHarvester -d example.com -b all" ;;
            2) tool_menu "spiderfoot" "Web-based OSINT automation framework." "spiderfoot -l 127.0.0.1:5001" ;;
            3) tool_menu "sherlock" "Check where a username exists across many sites." "sherlock username_here" ;;
            4) tool_menu "exiftool" "Display and edit file metadata (EXIF etc)." "exiftool image.jpg" ;;
            0) break ;;
            *) echo "Invalid option."; beep; pause ;;
        esac
    done
}

menu_exploit() {
    while true; do
        header
        echo -e "${ACCENT3}${BOLD}Exploitation / Post-Exploitation${RESET}"
        echo
        echo -e "${ACCENT3}1)${RESET} msfconsole   – Metasploit"
        echo -e "${ACCENT3}2)${RESET} searchsploit – Local exploit-db"
        echo -e "${ACCENT3}3)${RESET} ncat         – Reverse shells / pivoting"
        echo -e "${ACCENT3}0)${RESET} Back"
        echo
        read -rp "Select ▸ " c
        case "$c" in
            1) tool_menu "msfconsole" "Use Metasploit modules for exploitation and post-exploitation." "msfconsole" ;;
            2) tool_menu "searchsploit" "Search exploit-db from the terminal." "searchsploit apache 2.4" ;;
            3) tool_menu "ncat" "Set up listeners and reverse shells." "ncat -lvnp 4444" ;;
            0) break ;;
            *) echo "Invalid option."; beep; pause ;;
        esac
    done
}

menu_passwords() {
    while true; do
        header
        echo -e "${ACCENT3}${BOLD}Passwords / Hashes${RESET}"
        echo
        echo -e "${ACCENT3}1)${RESET} hashcat  – GPU cracking"
        echo -e "${ACCENT3}2)${RESET} john     – CPU cracking"
        echo -e "${ACCENT3}3)${RESET} hydra    – Online bruteforce"
        echo -e "${ACCENT3}4)${RESET} hashid   – Identify hash type"
        echo -e "${ACCENT3}0)${RESET} Back"
        echo
        read -rp "Select ▸ " c
        case "$c" in
            1) tool_menu "hashcat" "Crack hashes using GPU support." "hashcat -m 0 -a 0 hashes.txt wordlist.txt" ;;
            2) tool_menu "john" "Classic offline password cracker." "john --wordlist=rockyou.txt hashes.txt" ;;
            3) tool_menu "hydra" "Bruteforce network logins." "hydra -l admin -P passwords.txt ssh://target" ;;
            4) tool_menu "hashid" "Guess hash algorithm from a string." "hashid '5f4dcc3b5aa765d61d8327deb882cf99'" ;;
            0) break ;;
            *) echo "Invalid option."; beep; pause ;;
        esac
    done
}

menu_forensics() {
    while true; do
        header
        echo -e "${ACCENT3}${BOLD}Forensics / Malware${RESET}"
        echo
        echo -e "${ACCENT3}1)${RESET} autopsy    – GUI forensics"
        echo -e "${ACCENT3}2)${RESET} volatility – Memory forensics"
        echo -e "${ACCENT3}3)${RESET} binwalk    – Firmware/binary analysis"
        echo -e "${ACCENT3}4)${RESET} yara       – Rule-based detection"
        echo -e "${ACCENT3}0)${RESET} Back"
        echo
        read -rp "Select ▸ " c
        case "$c" in
            1) tool_menu "autopsy" "GUI suite for disk and image forensics." "autopsy" ;;
            2) tool_menu "volatility" "Analyse RAM images for processes, artefacts, creds." "volatility -f memory.img --info" ;;
            3) tool_menu "binwalk" "Search binaries for embedded files and signatures." "binwalk firmware.bin" ;;
            4) tool_menu "yara" "Detect patterns in files using YARA rules." "yara rules.yar suspicious_file" ;;
            0) break ;;
            *) echo "Invalid option."; beep; pause ;;
        esac
    done
}

menu_re() {
    while true; do
        header
        echo -e "${ACCENT3}${BOLD}Reverse Engineering${RESET}"
        echo
        echo -e "${ACCENT3}1)${RESET} ghidra   – Full RE suite"
        echo -e "${ACCENT3}2)${RESET} r2       – Radare2 core"
        echo -e "${ACCENT3}3)${RESET} cutter   – GUI over radare2"
        echo -e "${ACCENT3}4)${RESET} strings  – Quick binary peek"
        echo -e "${ACCENT3}0)${RESET} Back"
        echo
        read -rp "Select ▸ " c
        case "$c" in
            1) tool_menu "ghidra" "Disassembler/decompiler for many architectures." "ghidra" ;;
            2) tool_menu "r2" "Radare2 core (maybe installed as radare2)." "r2 binaryfile" ;;
            3) tool_menu "cutter" "Modern GUI for radare2." "cutter" ;;
            4) tool_menu "strings" "Dump printable strings from binaries." "strings binaryfile | less" ;;
            0) break ;;
            *) echo "Invalid option."; beep; pause ;;
        esac
    done
}

menu_blue_team() {
    while true; do
        header
        echo -e "${ACCENT3}${BOLD}Blue Team / DFIR${RESET}"
        echo
        echo -e "${ACCENT3}1)${RESET} wireshark – GUI packet analysis"
        echo -e "${ACCENT3}2)${RESET} tshark    – CLI packet capture"
        echo -e "${ACCENT3}3)${RESET} suricata  – IDS/IPS engine"
        echo -e "${ACCENT3}4)${RESET} zeek      – Network monitoring"
        echo -e "${ACCENT3}0)${RESET} Back"
        echo
        read -rp "Select ▸ " c
        case "$c" in
            1) tool_menu "wireshark" "Interactive packet analysis GUI." "wireshark" ;;
            2) tool_menu "tshark" "Command-line packet capture/analysis." "tshark -i eth0" ;;
            3) tool_menu "suricata" "IDS/IPS based on signatures and rules." "suricata -c /etc/suricata/suricata.yaml -i eth0" ;;
            4) tool_menu "zeek" "Network analysis framework (formerly Bro)." "zeek -i eth0" ;;
            0) break ;;
            *) echo "Invalid option."; beep; pause ;;
        esac
    done
}

update_from_repo() {
    header
    echo -e "${ACCENT3}${BOLD}Update Laplace from Repository${RESET}"
    echo
    echo -e "${MUTED}Current version:${RESET} ${ACCENT3}${LAPLACE_VERSION}${RESET}"
    echo -e "${MUTED}Repository:${RESET} ${GITHUB_REPO_URL}"
    echo

    # Check if Laplace lives inside a git repo
    if ! git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo -e "${ACCENT2}Laplace is not in a git repository.${RESET}"
        echo -e "${MUTED}Clone the repo and run Laplace from there to enable updates.${RESET}"
        pause
        return
    fi

    read -rp "Pull latest updates? [y/N] " ans
    case "$ans" in
        y|Y)
            echo
            git -C "$SCRIPT_DIR" pull
            echo
            echo -e "${ACCENT3}Laplace has been updated.${RESET}"
            echo -e "${MUTED}Restart Laplace to apply the new version.${RESET}"
            pause
            ;;
        *)
            echo "Cancelled."
            pause
            ;;
    esac
}
about_menu() {
    header
    echo -e "${ACCENT3}${BOLD}About Laplace${RESET}"
    echo
    echo -e "${MUTED}Version:${RESET} ${ACCENT3}${LAPLACE_VERSION}${RESET}"
    echo
    echo -e "${ACCENT3}${BOLD}PLAIN TEXT CREDENTIALS${RESET}"
    echo
    echo "GITHUB_USER      = ${GITHUB_USER}"
    echo "DISCORD_USER     = ${DISCORD_USER}"
    echo "GITHUB_REPO_URL  = ${GITHUB_REPO_URL}"
    echo
    echo -e "${ACCENT3}1)${RESET} Open GitHub repository"
    echo -e "${ACCENT3}2)${RESET} Pull update from repository"
    echo -e "${ACCENT3}0)${RESET} Back"
    echo
    read -rp "Select ▸ " c

    case "$c" in
        1)
            xdg-open "$GITHUB_REPO_URL" >/dev/null 2>&1 &
            ;;
        2)
            update_from_repo
            ;;
        0|*)
            ;;
    esac
}





# ------------ main menu ------------

main_menu() {
    while true; do
        header
        echo -e "${MUTED}Welcome back, user. Choose a stratum:${RESET}"
        echo
        echo -e "${ACCENT3}0)${RESET} Exit Laplace"
        echo -e "${ACCENT3}1)${RESET} Custom tools (Laplace memory)"
        echo -e "${ACCENT3}2)${RESET} Search tools"
        echo -e "${ACCENT3}3)${RESET} Web"
        echo -e "${ACCENT3}4)${RESET} Network / Scanning"
        echo -e "${ACCENT3}5)${RESET} WiFi / Wireless"
        echo -e "${ACCENT3}6)${RESET} OSINT / Recon"
        echo -e "${ACCENT3}7)${RESET} Exploitation"
        echo -e "${ACCENT3}8)${RESET} Passwords / Hashes"
        echo -e "${ACCENT3}9)${RESET} Forensics / Malware"
        echo -e "${ACCENT3}10)${RESET} Reverse Engineering"
        echo -e "${ACCENT3}11)${RESET} Blue Team / DFIR"
        echo -e "${ACCENT3}12)${RESET} Settings"
        echo -e "${ACCENT3}13)${RESET} About / Links"
        echo
        read -rp "Select ▸ " choice
        case "$choice" in
            0) echo -e "${MUTED}Laplace powers down. Goodbye, user.${RESET}"; exit 0 ;;
            1) menu_custom ;;
            2) search_tools ;;
            3) menu_web ;;
            4) menu_network ;;
            5) menu_wifi ;;
            6) menu_osint ;;
            7) menu_exploit ;;
            8) menu_passwords ;;
            9) menu_forensics ;;
            10) menu_re ;;
            11) menu_blue_team ;;
            12) settings_menu ;;
            13) about_menu ;;
            *) echo "Invalid option."; beep; pause ;;
        esac
    done
}

# ------------ bootstrap --------------

load_settings
populate_registry
startup_animation
prompt_password_if_needed
main_menu
