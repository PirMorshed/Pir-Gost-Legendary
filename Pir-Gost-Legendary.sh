#!/usr/bin/env bash

# ==========================================
#         PIR GOST - MASTER EDITION (v5.8)
# ==========================================

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "\033[0;31mPlease run as root (sudo).\033[0m"
   exec sudo -E bash "$0" "$@"
fi

# Detect Server Public IP (Priority: Interface eth0 for local IP)
get_ip() {
    local ip
    # ابتدا تلاش برای خواندن آی‌پی مستقیم از کارت شبکه eth0 (مطابق نیاز شما)
    ip=$(ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
    
    # اگر روی eth0 نبود، اولین آی‌پی شبکه سیستم را می‌گیرد
    if [[ -z "$ip" ]]; then
        ip=$(hostname -I | awk '{print $1}')
    fi
    
    # اگر هیچ آی‌پی داخلی یافت نشد، از سرویس‌های خارجی می‌پرسد
    if [[ -z "$ip" || "$ip" == "127.0.0.1" ]]; then
        ip=$(timeout 2s curl -s -4 api.ipify.org || timeout 2s curl -s -4 icanhazip.com)
    fi
    
    echo "$ip" | tr -d '[:space:]'
}
SERVER_IP=$(get_ip)

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

GOST_BIN="/usr/local/bin/gost"
META_DIR="/etc/pir_gost_meta"
IP_DB="$META_DIR/saved_ips.txt"
mkdir -p "$META_DIR"
touch "$IP_DB"

# --- PIR GOST BEAUTIFUL BANNER ---
banner() {
    clear

    WIDTH=90
    INNER_WIDTH=$((WIDTH - 2))

    logo=(
" ____  _        __  __                _              _ "
"|  _ \(_)_ __  |  \/  | ___  _ __ ___| |__   ___  __| |"
"| |_) | | '__| | |\/| |/ _ \| '__/ __| '_ \ / _ \/ _\` |"
"|  __/| | |    | |  | | (_) | |  \__ \ | | |  __/ (_| |"
"|_|   |_|_|    |_|  |_|\___/|_|  |___/_| |_|\___|\__,_|"
""
"+====================+"
"| Pir Gost Legendary |"
"+====================+"
    )

    # خط بالا
    printf "${CYAN}╔"
    printf '═%.0s' $(seq 1 $INNER_WIDTH)
    printf "╗${NC}\n"

    # چاپ لوگو به صورت وسط‌چین
    for line in "${logo[@]}"; do
        pad=$(( (INNER_WIDTH - ${#line}) / 2 ))

        printf "${CYAN}║${NC}"
        printf "%*s" "$pad" ""
        printf "${BOLD}${PURPLE}%s${NC}" "$line"
        printf "%*s" "$((INNER_WIDTH - pad - ${#line}))" ""
        printf "${CYAN}║${NC}\n"
    done

    # جداکننده
    printf "${CYAN}╠"
    printf '═%.0s' $(seq 1 $INNER_WIDTH)
    printf "╣${NC}\n"

    # SERVER IP
    ip_line="SERVER IP: $SERVER_IP"
    pad=$(( (INNER_WIDTH - ${#ip_line}) / 2 ))

    printf "${CYAN}║${NC}"
    printf "%*s" "$pad" ""
    printf "${BOLD}${WHITE}SERVER IP: ${GREEN}%s${NC}" "$SERVER_IP"
    printf "%*s" "$((INNER_WIDTH - pad - ${#ip_line}))" ""
    printf "${CYAN}║${NC}\n"

    # خط پایین
    printf "${CYAN}╚"
    printf '═%.0s' $(seq 1 $INNER_WIDTH)
    printf "╝${NC}\n"
}

# --- UDP & PING OPTIMIZER ---
optimize_udp_ping() {
    echo -e "${YELLOW}[*] Tuning Kernel for speed & low ping (BBR/UDP)...${NC}"
    if ! grep -q "Pir Gost UDP Optimization" /etc/sysctl.conf; then
        cp /etc/sysctl.conf /etc/sysctl.conf.bak
        cat >> /etc/sysctl.conf <<EOF

# Pir Gost UDP Optimization
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=262144
net.core.wmem_default=262144
net.core.netdev_max_backlog=25000
net.ipv4.udp_rmem_min=16384
net.ipv4.udp_wmem_min=16384
net.ipv4.ip_local_port_range=10000 65535
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets=2000000
EOF
        sysctl -p > /dev/null 2>&1
        echo -e "${GREEN}[+] BBR and UDP Optimizer applied.${NC}"
    else
        echo -e "${GREEN}[+] Optimization already exists.${NC}"
    fi

    # --- LOG MANAGEMENT TO PREVENT DISK FULL ---
    echo -e "${YELLOW}[*] Configuring log rotation to save disk space...${NC}"
    if [ -f /etc/systemd/journald.conf ]; then
        sed -i 's/#SystemMaxUse=/SystemMaxUse=100M/' /etc/systemd/journald.conf
        sed -i 's/#RuntimeMaxUse=/RuntimeMaxUse=100M/' /etc/systemd/journald.conf
        systemctl restart systemd-journald
    fi
    journalctl --vacuum-size=100M > /dev/null 2>&1
    truncate -s 0 /var/log/syslog > /dev/null 2>&1
    truncate -s 0 /var/log/syslog.1 > /dev/null 2>&1
    echo -e "${GREEN}[+] Log management applied (Max 100MB).${NC}"
}

# --- IP & PORT MANAGER ---
manage_targets() {
    banner
    echo -e "${BOLD}${WHITE}╔═══════════════════════════════════════════════════╗${NC}"
    printf "${BOLD}${WHITE}║ Local IP  : ${CYAN}%-37s${NC}${BOLD}${WHITE}║${NC}\n" "$SERVER_IP"
    echo -e "${BOLD}${WHITE}╚═══════════════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}=========================================================${NC}"
    echo -e "${BOLD}${PURPLE}                 SELECT REMOTE IP ADDRESS${NC}"
    echo -e "${YELLOW}=========================================================${NC}"
    
    mapfile -t saved_ips < <(head -n 3 "$IP_DB")
    
    for i in {0..2}; do
        idx=$((i+1))
        ip="${saved_ips[$i]}"
        if [[ -z "$ip" ]]; then
            echo -e " ${idx}) ${RED}[Empty]${NC}"
        else
            echo -e " ${idx}) ${GREEN}$ip${NC}"
        fi
    done
    echo -e " 4) ${CYAN}Enter a new IP address${NC}"
    echo -e " 0) ${WHITE}Back${NC}"
    echo -e "${YELLOW}---------------------------------------------------------${NC}"
    read -p " Selection: " ip_choice
    echo -e "${YELLOW}>> Selected: ${ip_choice:-0}${NC}"

    case "$ip_choice" in
        1|2|3)
            FINAL_REMOTE_IP="${saved_ips[$((ip_choice-1))]}"
            if [[ -z "$FINAL_REMOTE_IP" ]]; then
                read -p " Enter IP for slot $ip_choice: " NEW_IP
                echo -e "${YELLOW}>> IP Entered: $NEW_IP${NC}"
                if [ $(wc -l < "$IP_DB") -lt $ip_choice ]; then
                    while [ $(wc -l < "$IP_DB") -lt $ip_choice ]; do echo "" >> "$IP_DB"; done
                fi
                sed -i "${ip_choice}s/.*/$NEW_IP/" "$IP_DB"
                FINAL_REMOTE_IP="$NEW_IP"
            fi
            ;;
        4)
            read -p " Enter new IP: " FINAL_REMOTE_IP
            echo -e "${YELLOW}>> IP Entered: $FINAL_REMOTE_IP${NC}"
            echo "$FINAL_REMOTE_IP" >> "$IP_DB"
            awk '!seen[$0]++' "$IP_DB" > "${IP_DB}.tmp" && mv "${IP_DB}.tmp" "$IP_DB"
            ;;
        *) return 1 ;;
    esac

    echo -e "\n${YELLOW}=========================================================${NC}"
    echo -e " 1) ${BLUE}Cloudflare HTTP Ports${NC} (80,8080,8880,2052,2082,2086,2095)"
    echo -e " 2) ${BLUE}Cloudflare HTTPS Ports${NC} (443,2053,2083,2087,2096,8443,110)"
    echo -e " 3) ${BLUE}Custom Ports${NC} (Manual entry - comma or range)"
    echo -e " 0) ${WHITE}Back${NC}"
    echo -e "${YELLOW}=========================================================${NC}"
    read -p " Selection: " port_choice
    echo -e "${YELLOW}>> Selected: ${port_choice:-0}${NC}"

    case "$port_choice" in
        1) FINAL_PORTS="80,8080,8880,2052,2082,2086,2095" ;;
        2) FINAL_PORTS="443,2053,2083,2087,2096,8443,110" ;;
        3) read -p " Enter ports (e.g. 80,443): " FINAL_PORTS 
           echo -e "${YELLOW}>> Ports Entered: $FINAL_PORTS${NC}" ;;
        *) return 1 ;;
    esac
    
    echo -e "${GREEN}Target set to: $FINAL_REMOTE_IP with ports: $FINAL_PORTS${NC}"
    sleep 1
    return 0
}

# --- Install Gost ---
install_gost() {
    if [[ ! -f "$GOST_BIN" ]]; then
        ARCH=$(uname -m)
        [[ "$ARCH" == "x86_64" ]] && G_ARCH="amd64" || G_ARCH="armv8"
        echo -e "${YELLOW}[*] Downloading Pir-Gost Core...${NC}"
        wget -qO- "https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-${G_ARCH}-2.11.5.gz" | gunzip > "$GOST_BIN"
        chmod +x "$GOST_BIN"
    fi
}

# --- Deployment Logic ---
deploy_tunnel() {
    local modify_name=$1
    install_gost
    optimize_udp_ping
    
    banner
    if [[ -z "$modify_name" ]]; then
        echo -e "${BOLD}${CYAN}[ CREATE NEW INSTANCE ]${NC}\n"
        read -p "   Instance Name (e.g. game, cdn): " T_NAME
        echo -e "${YELLOW}>> Name: ${T_NAME:-pir}${NC}"
    else
        echo -e "${BOLD}${YELLOW}[ RE-CONFIGURING INSTANCE: $modify_name ]${NC}\n"
        T_NAME=$modify_name
    fi
    [[ -z "$T_NAME" ]] && T_NAME="pir"
    SERVICE_NAME="gost-${T_NAME}.service"

    echo -e "\n${BLUE}1. Target Configuration:${NC}"
    if [[ -n "$FINAL_REMOTE_IP" && -n "$FINAL_PORTS" ]]; then
        echo -e "   Current Target: ${GREEN}$FINAL_REMOTE_IP${NC} Ports: ${GREEN}$FINAL_PORTS${NC}"
        read -p "   Use these settings? [Y/n]: " use_saved
        echo -e "${YELLOW}>> Selected: ${use_saved:-Y}${NC}"
        if [[ "$use_saved" == "n" ]]; then
            manage_targets || return
        fi
    else
        manage_targets || return
    fi

    echo -e "\n${BLUE}2. Select Server Role:${NC}"
    echo "   1) IRAN (Client)"
    echo "   2) KHAREJ (Server)"
    echo -e "   ${PURPLE}0) Back${NC}"
    read -p "   Selection: " side_opt
    echo -e "${YELLOW}>> Selected: ${side_opt:-0}${NC}"
    [[ "$side_opt" == "0" ]] && return

    read -p "   Tunnel Port (Communication Port): " TUNNEL_PORT
    echo -e "${YELLOW}>> Tunnel Port: $TUNNEL_PORT${NC}"

    echo -e "\n${BLUE}3. Select Transport Protocol:${NC}"
    echo "   1) relay+mtls"
    echo "   2) relay+mwss"
    echo "   3) relay+grpc"
    echo "   4) relay+mtcp"
    echo "   5) relay+tls"
    echo "   6) relay+wss"
    echo "   7) relay+ws"
    echo "   8) relay+h2"
    echo "   9) relay+quic"
    echo "  10) relay+kcp"
    echo "  11) relay+tcp"
    echo -e "   ${PURPLE}0) Back${NC}"
    read -p "   Choice [1-11]: " p_opt
    echo -e "${YELLOW}>> Selected: ${p_opt:-1}${NC}"
    [[ "$p_opt" == "0" ]] && return

    case "$p_opt" in
        1) PROTO="relay+mtls" ;; 2) PROTO="relay+mwss" ;; 3) PROTO="relay+grpc" ;;
        4) PROTO="relay+mtcp" ;; 5) PROTO="relay+tls" ;; 6) PROTO="relay+wss" ;;
        7) PROTO="relay+ws" ;; 8) PROTO="relay+h2" ;; 9) PROTO="relay+quic" ;;
        10) PROTO="relay+kcp" ;; 11) PROTO="relay+tcp" ;; *) PROTO="relay+mtls" ;;
    esac

    echo -e "\n${BLUE}4. Feature Toggles (Default: Yes):${NC}"
    read -p "   Enable TCP Keepalive? [Y/n]: " ok
    echo -e "${YELLOW}>> Selected: ${ok:-Y}${NC}"
    read -p "   Enable MPTCP? [Y/n]: " om
    echo -e "${YELLOW}>> Selected: ${om:-Y}${NC}"
    read -p "   Enable Nodelay? [Y/n]: " on
    echo -e "${YELLOW}>> Selected: ${on:-Y}${NC}"
    read -p "   Enable UDP TTL (Gaming Fix)? [Y/n]: " ou
    echo -e "${YELLOW}>> Selected: ${ou:-Y}${NC}"
    read -p "   Enable Memory Opt (GC=20)? [Y/n]: " og
    echo -e "${YELLOW}>> Selected: ${og:-Y}${NC}"
    read -p "   Enable Anti-DPI Refresh (2h)? [Y/n]: " or
    echo -e "${YELLOW}>> Selected: ${or:-Y}${NC}"

    [[ "$ok" != "n" ]] && Q_K="&keepalive=true" || Q_K=""
    [[ "$om" != "n" ]] && Q_M="&mptcp=true" || Q_M=""
    [[ "$on" != "n" ]] && Q_N="&nodelay=true" || Q_N=""
    [[ "$ou" != "n" ]] && Q_U="&ttl=60s" || Q_U=""
    [[ "$og" != "n" ]] && M_GC="GOGC=20" || M_GC="GOGC=100"
    [[ "$or" != "n" ]] && R_TIME="7200" || R_TIME="0"

    QUERY="?${Q_K}${Q_M}${Q_N}${Q_U}"
    QUERY="${QUERY/\?&/\?}"
    [[ "$QUERY" == "?" ]] && QUERY=""

    if [[ "$side_opt" == "1" ]]; then
        IFS=',' read -r -a p_list <<< "$FINAL_PORTS"
        LISTENERS=""
        for p in "${p_list[@]}"; do
            LISTENERS+="-L=tcp://:${p}/127.0.0.1:${p} -L=udp://:${p}/127.0.0.1:${p} "
        done
        EXEC="$GOST_BIN $LISTENERS -F=${PROTO}://${FINAL_REMOTE_IP}:${TUNNEL_PORT}${QUERY}"
    else
        [[ "$FINAL_PORTS" == *"53"* ]] && (sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf; systemctl restart systemd-resolved)
        EXEC="$GOST_BIN -L=${PROTO}://:${TUNNEL_PORT}${QUERY}"
    fi

    cat > "/etc/systemd/system/$SERVICE_NAME" <<EOF
[Unit]
Description=Pir-Gost: $T_NAME
After=network.target

[Service]
Type=simple
Environment=$M_GC
StandardOutput=null
StandardError=null
Restart=always
RestartSec=5
$( [[ "$R_TIME" != "0" ]] && echo "RuntimeMaxSec=$R_TIME" )
ExecStart=$EXEC
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload && systemctl restart "$SERVICE_NAME" && systemctl enable "$SERVICE_NAME"
    
    banner
    echo -e "${BOLD}${GREEN}[✔] PIR GOST INSTANCE '$T_NAME' DEPLOYED!${NC}"
    echo -e "${BOLD}${WHITE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║                     DEPLOYMENT CONFIGURATION LOG                     ║${NC}"
    echo -e "${BOLD}${WHITE}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    
    role_str=$([[ "$side_opt" == "1" ]] && echo "IRAN (Client)" || echo "KHAREJ (Server)")
    printf "${BOLD}${WHITE}║ ${CYAN}%-25s${NC} : ${YELLOW}%-40s${NC} ${BOLD}${WHITE}║${NC}\n" "Instance Name" "$T_NAME"
    printf "${BOLD}${WHITE}║ ${CYAN}%-25s${NC} : ${YELLOW}%-40s${NC} ${BOLD}${WHITE}║${NC}\n" "Server Role" "$role_str"
    printf "${BOLD}${WHITE}║ ${CYAN}%-25s${NC} : ${YELLOW}%-40s${NC} ${BOLD}${WHITE}║${NC}\n" "Protocol" "$PROTO"
    printf "${BOLD}${WHITE}║ ${CYAN}%-25s${NC} : ${YELLOW}%-40s${NC} ${BOLD}${WHITE}║${NC}\n" "Tunnel Port" "$TUNNEL_PORT"
    printf "${BOLD}${WHITE}║ ${CYAN}%-25s${NC} : ${YELLOW}%-40s${NC} ${BOLD}${WHITE}║${NC}\n" "Remote IP" "$FINAL_REMOTE_IP"
    
    echo -e "${BOLD}${WHITE}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    
    show_status() {
        if [[ "$1" != "n" ]]; then echo -e "${GREEN}ENABLED ${NC}"; else echo -e "${RED}DISABLED${NC}"; fi
    }
    
    printf "${BOLD}${WHITE}║ ${WHITE}%-25s${NC} : %-50b ${BOLD}${WHITE}║${NC}\n" "TCP Keepalive" "$(show_status $ok)"
    printf "${BOLD}${WHITE}║ ${WHITE}%-25s${NC} : %-50b ${BOLD}${WHITE}║${NC}\n" "MPTCP Support" "$(show_status $om)"
    printf "${BOLD}${WHITE}║ ${WHITE}%-25s${NC} : %-50b ${BOLD}${WHITE}║${NC}\n" "TCP Nodelay" "$(show_status $on)"
    printf "${BOLD}${WHITE}║ ${WHITE}%-25s${NC} : %-50b ${BOLD}${WHITE}║${NC}\n" "UDP TTL (Gaming Fix)" "$(show_status $ou)"
    printf "${BOLD}${WHITE}║ ${WHITE}%-25s${NC} : %-50b ${BOLD}${WHITE}║${NC}\n" "Memory Optimization" "$(show_status $og)"
    printf "${BOLD}${WHITE}║ ${WHITE}%-25s${NC} : %-50b ${BOLD}${WHITE}║${NC}\n" "Anti-DPI Refresh (2h)" "$(show_status $or)"
    
    echo -e "${BOLD}${WHITE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    read -p "Press ENTER to return to menu..." _
}

# --- Management Dashboard ---
manage_tunnels() {
    while true; do
        banner
        echo -e "${BOLD}${CYAN}[ PIR TUNNEL MANAGER ]${NC}\n"
        
        tunnels=( $(ls /etc/systemd/system/gost-*.service 2>/dev/null) )
        if [[ ${#tunnels[@]} -eq 0 ]]; then
            echo -e "   ${RED}No active Pir tunnels found.${NC}"
            echo -e "   ${PURPLE}0) Back${NC}"
            read -p " Selection: " _
            return
        fi

        for i in "${!tunnels[@]}"; do
            name=$(basename "${tunnels[$i]}" .service)
            status=$(systemctl is-active "$name")
            [[ "$status" == "active" ]] && s_color=$GREEN || s_color=$RED
            printf "   %2d) %-25s [ %b%-10s${NC} ]\n" "$((i+1))" "$name" "$s_color" "$status"
        done
        echo -e "\n   ${PURPLE}0) Back to Main Menu${NC}"
        
        read -p "   Select Instance: " t_idx
        echo -e "${YELLOW}>> Selected: ${t_idx:-0}${NC}"
        [[ "$t_idx" == "0" || -z "$t_idx" ]] && break
        
        selected_service=$(basename "${tunnels[$((t_idx-1))]}" .service)
        
        while true; do
            banner
            echo -e "${BOLD}${YELLOW}TUNNEL PANEL: $selected_service${NC}\n"
            echo "   1) Start Service"
            echo "   2) Stop Service"
            echo "   3) Restart Service"
            echo "   4) Check Status & Logs"
            echo "   5) Edit / Re-Configure"
            echo "   6) Deep Delete (Root Cleanup)"
            echo -e "   ${PURPLE}0) Back to List${NC}"
            read -p "   Choice: " m_opt
            echo -e "${YELLOW}>> Selected: ${m_opt:-0}${NC}"
            
            case "$m_opt" in
                1) systemctl start "$selected_service" ;;
                2) systemctl stop "$selected_service" ;;
                3) systemctl restart "$selected_service" ;;
                4) 
                   banner
                   systemctl status "$selected_service" --no-pager
                   journalctl -u "$selected_service" -n 10 --no-pager
                   read -p "Press ENTER to return..." _ ;;
                5) deploy_tunnel "$selected_service" ; break ;;
                6) 
                   systemctl stop "$selected_service" && systemctl disable "$selected_service"
                   rm -f "/etc/systemd/system/${selected_service}.service"
                   systemctl daemon-reload
                   echo -e "${GREEN}[✔] Cleanly removed.${NC}"
                   sleep 1 ; break ;;
                0) break ;;
            esac
        done
    done
}

# --- Watchdog ---
cron_manager() {
    banner
    echo -e "${BOLD}${PURPLE}[ PIR SENTRY - WATCHDOG ]${NC}\n"
    echo "   1) Enable Watchdog"
    echo "   2) Disable Watchdog"
    echo -e "   ${PURPLE}0) Back${NC}"
    read -p "   Selection: " c_opt
    echo -e "${YELLOW}>> Selected: ${c_opt:-0}${NC}"
    [[ "$c_opt" == "0" ]] && return
    
    local w_script="/usr/local/bin/pir_watchdog.sh"
    case "$c_opt" in
        1)
           cat > "$w_script" <<'EOF'
#!/usr/bin/env bash
for s in $(ls /etc/systemd/system/gost-*.service 2>/dev/null | xargs -n1 basename | sed 's/\.service//'); do
    if ! systemctl is-active --quiet "$s"; then systemctl restart "$s"; fi
done
EOF
           chmod +x "$w_script"
           (crontab -l 2>/dev/null | grep -v "$w_script"; echo "* * * * * $w_script") | crontab -
           echo -e "${GREEN}[✔] Sentry Active.${NC}" ;;
        2)
           crontab -l 2>/dev/null | grep -v "$w_script" | crontab -
           rm -f "$w_script"
           echo -e "${RED}[!] Sentry Disabled.${NC}" ;;
    esac
    sleep 1
}

# --- Uninstall ---
uninstall_pir() {
    banner
    echo -e "${BOLD}${RED}[ NUCLEAR UNINSTALLER ]${NC}\n"
    echo "   1) Delete One Instance"
    echo "   2) WIPE ALL DATA (Full Clean)"
    echo -e "   ${PURPLE}0) Back${NC}"
    read -p "   Selection: " u_opt
    echo -e "${YELLOW}>> Selected: ${u_opt:-0}${NC}"
    [[ "$u_opt" == "0" ]] && return
    
    case "$u_opt" in
        1) manage_tunnels ;;
        2) 
           read -p "   Are you sure? (y/n): " confirm
           echo -e "${YELLOW}>> Choice: ${confirm:-n}${NC}"
           if [[ "$confirm" == "y" ]]; then
               pkill -9 gost
               rm -f /etc/systemd/system/gost-*.service
               rm -f "$GOST_BIN"
               rm -rf "$META_DIR"
               crontab -l 2>/dev/null | grep -v "pir_watchdog" | crontab -
               systemctl daemon-reload
               echo -e "${GREEN}[✔] System Cleaned.${NC}"
               sleep 2
           fi ;;
    esac
}

# --- MAIN MENU ---
while true; do
    banner
    echo -e "   1) ${CYAN}Manage Saved IP/Ports (Destination)${NC}"
    echo -e "   2) ${GREEN}Deploy New Pir-Tunnel${NC}"
    echo -e "   3) ${YELLOW}Manage / Edit Pir-Tunnels${NC}"
    echo -e "   4) ${PURPLE}Watchdog (Pir Sentry)${NC}"
    echo -e "   5) ${RED}Nuclear Uninstall${NC}"
    echo -e "   0) ${WHITE}Exit${NC}"
    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
    read -p " Select Option: " main_choice
    echo -e "${YELLOW}>> Selected: ${main_choice:-0}${NC}"

    case "$main_choice" in
        1) manage_targets ;;
        2) deploy_tunnel ;;
        3) manage_tunnels ;;
        4) cron_manager ;;
        5) uninstall_pir ;;
        0) exit 0 ;;
    esac
done
