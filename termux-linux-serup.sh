--- START OF FILE termux-linux-setup.sh ---

#!/data/data/com.termux/files/usr/bin/bash
#######################################################
#  Termux Linux Setup Script - VNC & Enhanced
#
#  Features:
#  - Choice of Desktop Environment (XFCE, LXQt, MATE, KDE)
#  - VNC Server (TigerVNC) instead of Termux-X11
#  - Smart GPU acceleration detection (Turnip/Zink)
#  - Productivity and Media tools (VLC, Firefox)
#  - Python & Web Dev environment pre-installed
#  - Windows App Support (Wine/Hangover)
#  - Enhanced error handling & user feedback
#  - Disk space check
#######################################################

# ============== CONFIGURATION ==============
TOTAL_STEPS=13 # Increased for VNC, disk check, and more robust steps
CURRENT_STEP=0
DE_CHOICE="1"
DE_NAME="XFCE4"
VNC_PORT="5901"
VNC_DISPLAY=":1"
VNC_PASSWORD="" # Will be set by user

# ============== COLORS ==============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

# ============== PROGRESS FUNCTIONS ==============
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    
    FILLED=$((PERCENT / 5))
    EMPTY=$((20 - FILLED))
    
    BAR="${GREEN}"
    for ((i=0; i<FILLED; i++)); do BAR+="*"; done
    BAR+="${GRAY}"
    for ((i=0; i<EMPTY; i++)); do BAR+="-"; done
    BAR+="${NC}"
    
    echo ""
    echo -e "${WHITE}------------------------------------------------------------${NC}"
    echo -e "${CYAN}  OVERALL PROGRESS: ${WHITE}Step ${CURRENT_STEP}/${TOTAL_STEPS}${NC} ${BAR} ${WHITE}${PERCENT}%${NC}"
    echo -e "${WHITE}------------------------------------------------------------${NC}"
    echo ""
}

spinner() {
    local pid=$1
    local message=$2
    local spin='-\|/'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r  [*] ${message} ${CYAN}${spin:$i:1}${NC}  "
        sleep 0.1
    done
    
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        printf "\r  [+] ${message}                    \n"
    else
        printf "\r  [-] ${message} ${RED}(failed)${NC}     \n"
        echo -e "${RED}ERROR: Installation failed for '${message}'. Exiting.${NC}"
        exit 1
    fi
    
    return $exit_code
}

install_pkg() {
    local pkg=$1
    local name=${2:-$pkg}
    (DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::="--force-confold" $pkg > /dev/null 2>&1) &
    spinner $! "Installing ${name}..."
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Could not install package '${pkg}'. Please check your internet connection or Termux repositories.${NC}"
        exit 1
    fi
}

# ============== BANNER ==============
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'BANNER'
    -------------------------------------------
                                               
     Termux Linux Setup Script - VNC Edition   
                                               
    -------------------------------------------
BANNER
    echo -e "${NC}"
    echo ""
}

# ============== DEVICE & USER SELECTION ==============
setup_environment() {
    echo -e "${PURPLE}[*] Detecting your device...${NC}"
    echo ""
    
    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
    ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    CPU_ABI=$(getprop ro.product.cpu.abi 2>/dev/null || echo "arm64-v8a")
    GPU_VENDOR=$(getprop ro.hardware.egl 2>/dev/null || echo "")
    
    echo -e "  [*] Device: ${WHITE}${DEVICE_BRAND} ${DEVICE_MODEL}${NC}"
    echo -e "  [*] Android: ${WHITE}${ANDROID_VERSION}${NC}"
    
    if [[ "$GPU_VENDOR" == *"adreno"* ]] || [[ "$DEVICE_BRAND" == *"samsung"* ]] || [[ "$DEVICE_BRAND" == *"Samsung"* ]] || [[ "$DEVICE_BRAND" == *"oneplus"* ]] || [[ "$DEVICE_BRAND" == *"xiaomi"* ]]; then
        GPU_DRIVER="freedreno"
        echo -e "  [*] GPU: ${WHITE}Adreno (Qualcomm) - Hardware Acceleration Supported${NC}"
    else
        GPU_DRIVER="zink_native"
        echo -e "  [*] GPU: ${WHITE}Non-Adreno - Zink Native Vulkan${NC}"
        echo -e "${YELLOW}      [!] WARNING: Your device may not fully support advanced GPU acceleration.${NC}"
        echo -e "${YELLOW}      [!] We HIGHLY RECOMMEND choosing LXQt or XFCE for smooth performance.${NC}"
    fi
    echo ""
    
    echo -e "${CYAN}Please choose your Desktop Environment:${NC}"
    echo -e "  ${WHITE}1) XFCE4${NC}       (Recommended - Fast, Customizable, macOS style dock)"
    echo -e "  ${WHITE}2) LXQt${NC}        (Ultra lightweight - Best for low end devices)"
    echo -e "  ${WHITE}3) MATE${NC}        (Classic UI, moderately heavy)"
    echo -e "  ${WHITE}4) KDE Plasma${NC}  (Very heavy - Modern, Windows 11 style, requires strong GPU/RAM)"
    echo ""
    while true; do
        read -p "Enter number (1-4) [default: 1]: " DE_INPUT
        DE_INPUT=${DE_INPUT:-1}
        if [[ "$DE_INPUT" =~ ^[1-4]$ ]]; then
            DE_CHOICE="$DE_INPUT"
            break
        else
            echo "Invalid input. Please enter 1, 2, 3, or 4."
        fi
    done
    
    case $DE_CHOICE in
        1) DE_NAME="XFCE4";;
        2) DE_NAME="LXQt";;
        3) DE_NAME="MATE";;
        4) DE_NAME="KDE Plasma";;
    esac
    
    echo -e "\n${GREEN}[+] Selected: ${DE_NAME}.${NC}"
    sleep 2
}

# ============== STEP 1: PRE-REQUISITE CHECKS ==============
step_prereq_checks() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Performing pre-installation checks...${NC}"
    echo ""

    # Check for Termux storage permission
    termux-setup-storage -c > /dev/null 2>&1
    if [ ! -d "/sdcard" ]; then
        echo -e "${RED}ERROR: Termux storage permission not granted. Please run 'termux-setup-storage' and grant permission.${NC}"
        exit 1
    fi
    echo -e "  [+] Termux storage permission confirmed."

    # Check free disk space (minimum 5GB recommended, 10GB for KDE)
    REQUIRED_SPACE_MB=5000 # 5GB
    if [ "$DE_CHOICE" == "4" ]; then
        REQUIRED_SPACE_MB=10000 # 10GB for KDE
    fi

    FREE_SPACE_MB=$(df -m /data | awk 'NR==2 {print $4}')
    if [ "$FREE_SPACE_MB" -lt "$REQUIRED_SPACE_MB" ]; then
        echo -e "${RED}ERROR: Insufficient disk space. You need at least ${REQUIRED_SPACE_MB}MB, but only ${FREE_SPACE_MB}MB is available.${NC}"
        echo -e "${RED}Please free up some space and try again.${NC}"
        exit 1
    fi
    echo -e "  [+] Sufficient disk space (${FREE_SPACE_MB}MB available) confirmed."

    # Check for internet connection (simple ping)
    if ! ping -c 1 google.com > /dev/null 2>&1; then
        echo -e "${RED}ERROR: No internet connection detected. Please connect to the internet and try again.${NC}"
        exit 1
    fi
    echo -e "  [+] Internet connection confirmed."
}


# ============== STEP 2: UPDATE SYSTEM ==============
step_update() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Updating system packages...${NC}"
    echo ""
    (DEBIAN_FRONTEND=noninteractive apt-get update -y > /dev/null 2>&1) &
    spinner $! "Updating package lists..."
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Failed to update package lists. Please check your internet connection and Termux setup.${NC}"
        exit 1
    fi
    (DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -q -o Dpkg::Options::="--force-confold" > /dev/null 2>&1) &
    spinner $! "Upgrading installed packages..."
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}WARNING: Some packages might not have upgraded successfully. Continuing anyway...${NC}"
    fi
}

# ============== STEP 3: INSTALL REPOSITORIES ==============
step_repos() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Adding package repositories...${NC}"
    echo ""
    install_pkg "x11-repo" "X11 Repository"
    install_pkg "tur-repo" "TUR Repository (Firefox)"
}

# ============== STEP 4: INSTALL VNC SERVER ==============
step_vnc() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing VNC Server...${NC}"
    echo ""
    install_pkg "tigervnc" "TigerVNC Server"

    echo ""
    echo -e "${CYAN}Please set a VNC password now.${NC}"
    echo -e "${YELLOW}This password will be required to connect to your Linux desktop.${NC}"
    echo -e "${YELLOW}It must be between 6 and 8 characters long.${NC}"

    while true; do
        read -s -p "Enter VNC password: " VNC_PASSWORD
        echo
        read -s -p "Verify VNC password: " VNC_PASSWORD_VERIFY
        echo

        if [[ "$VNC_PASSWORD" == "$VNC_PASSWORD_VERIFY" ]] && [[ "${#VNC_PASSWORD}" -ge 6 ]] && [[ "${#VNC_PASSWORD}" -le 8 ]]; then
            break
        else
            echo -e "${RED}Passwords do not match or are not 6-8 characters. Please try again.${NC}"
        fi
    done

    mkdir -p ~/.vnc
    echo "$VNC_PASSWORD" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd
    echo -e "  [+] VNC password set successfully."
}

# ============== STEP 5: INSTALL DESKTOP ==============
step_desktop() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing ${DE_NAME} Desktop...${NC}"
    echo ""
    
    if [ "$DE_CHOICE" == "1" ]; then
        # XFCE
        install_pkg "xfce4" "XFCE4 Desktop"
        install_pkg "xfce4-terminal" "XFCE4 Terminal"
        install_pkg "xfce4-whiskermenu-plugin" "Whisker Menu"
        install_pkg "plank-reloaded" "Plank Dock"
        install_pkg "thunar" "Thunar File Manager"
        install_pkg "mousepad" "Mousepad Editor"
    elif [ "$DE_CHOICE" == "2" ]; then
        # LXQt
        install_pkg "lxqt" "LXQt Desktop"
        install_pkg "qterminal" "QTerminal"
        install_pkg "pcmanfm-qt" "PCManFM-Qt"
        install_pkg "featherpad" "FeatherPad"
    elif [ "$DE_CHOICE" == "3" ]; then
        # MATE
        install_pkg "mate" "MATE Desktop"
        install_pkg "mate-tweak" "MATE Tweak"
        install_pkg "plank-reloaded" "Plank Dock"
        install_pkg "mate-terminal" "MATE Terminal"
    elif [ "$DE_CHOICE" == "4" ]; then
        # KDE
        install_pkg "plasma-desktop" "KDE Plasma"
        install_pkg "konsole" "Konsole"
        install_pkg "dolphin" "Dolphin"
    fi
}

# ============== STEP 6: INSTALL GPU DRIVERS ==============
step_gpu() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing GPU Acceleration...${NC}"
    echo ""
    install_pkg "mesa-zink" "Mesa Zink Core"
    if [ "$GPU_DRIVER" == "freedreno" ]; then
        install_pkg "mesa-vulkan-icd-freedreno" "Turnip Adreno Driver"
    fi
    # Removed: install_pkg "vulkan-loader-android" "Vulkan Loader"
}

# ============== STEP 7: INSTALL AUDIO ==============
step_audio() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Audio...${NC}"
    echo ""
    install_pkg "pulseaudio" "PulseAudio Server"
}

# ============== STEP 8: INSTALL APPS (VS Code, VLC, etc.) ==============
step_apps() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Media & Dev Apps...${NC}"
    echo ""
    install_pkg "firefox" "Firefox Browser"
    install_pkg "vlc" "VLC Media Player"
    install_pkg "git" "Git Version Control"
    install_pkg "wget" "Wget Downloader"
    install_pkg "curl" "cURL"
    install_pkg "neofetch" "Neofetch System Info" # Added neofetch
}

# ============== STEP 9: PYTHON & FLASK DEMO ==============
step_python() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Python Environment...${NC}"
    echo ""
    install_pkg "python" "Python 3"
    
    (pip install flask > /dev/null 2>&1) &
    spinner $! "Installing Flask Web Framework..."
    
    # Create Python Demo
    mkdir -p ~/demo_python
    cat > ~/demo_python/app.py << 'EOF'
from flask import Flask, render_template_string
app = Flask(__name__)

@app.route("/")
def hello():
    return render_template_string("""
    <html>
        <body style="background-color:#1e1e1e;color:#00ff00;font-family:monospace;text-align:center;padding:50px">
            <h1>Hardware Accelerated Linux</h1>
            <h3>This Python server is running natively on a Snapdragon Android phone!</h3>
        </body>
    </html>
    """)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF
    echo -e "  [+] Python Web Demo created in ~/demo_python"
}

# ============== STEP 10: INSTALL WINE ==============
step_wine() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Windows Support (Wine/Box64)...${NC}"
    echo ""
    (pkg remove wine-stable -y > /dev/null 2>&1) &
    spinner $! "Removing old Wine versions (if any)..."
    
    install_pkg "hangover-wine" "Wine Compatibility Layer"
    install_pkg "hangover-wowbox64" "Box64 Wrapper"
    
    ln -sf /data/data/com.termux/files/usr/opt/hangover-wine/bin/wine /data/data/com.termux/files/usr/bin/wine
    ln -sf /data/data/com.termux/files/usr/opt/hangover-wine/bin/winecfg /data/data/com.termux/files/usr/bin/winecfg
    echo -e "  [+] Wine and Box64 configured."
}

# ============== STEP 11: CONFIGURE DESKTOP ENVIRONMENT FOR VNC ==============
step_de_config_vnc() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Configuring Desktop Environment for VNC...${NC}"
    echo ""

    mkdir -p ~/.vnc

    # Create xstartup script for VNC
    cat > ~/.vnc/xstartup << EOF
#!/data/data/com.termux/files/usr/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Load GPU & XDG environment variables
source ~/.config/linux-gpu.sh 2>/dev/null

# Start PulseAudio for sound (if not already running)
pulseaudio --kill 2>/dev/null
pulseaudio --start --exit-idle-time=-1 &
export PULSE_SERVER=127.0.0.1

# Start Desktop Environment
case "$DE_CHOICE" in
    1) # XFCE4
        [ -x /etc/X11/Xsession ] && /etc/X11/Xsession
        ;;
    2) # LXQt
        startlxqt
        ;;
    3) # MATE
        mate-session
        ;;
    4) # KDE Plasma
        dbus-launch startplasma-x11
        ;;
esac
EOF
    chmod +x ~/.vnc/xstartup
    echo -e "  [+] ~/.vnc/xstartup created for ${DE_NAME}."

    # Specific DE fixes/autostart
    case "$DE_CHOICE" in
        1) # XFCE4
            mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml
            # Disable XFCE's own window manager to avoid conflicts with VNC
            echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
            echo "<channel name=\"xfce4-session\" version=\"1.0\">" >> ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
            echo "<property name=\"general\" type=\"empty\">" >> ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
            echo "<property name=\"SaveOnExit\" type=\"bool\" value=\"false\"/>" >> ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
            echo "<property name=\"SessionName\" type=\"string\" value=\"Default\"/>" >> ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
            echo "</property>" >> ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
            echo "<property name=\"sessions\" type=\"empty\">" >> ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
            echo "<property name=\"Failsafe\" type=\"empty\">" >> ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
            echo "<property name=\"IsFailsafe\" type=\"bool\" value=\"true\"/>" >> ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
            echo "</property>" >> ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
            echo "</channel>" >> ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
            echo -e "  [+] XFCE4 session management adjusted for VNC."
            ;;
        4) # KDE Plasma - Needs a custom session script
            # KDE needs a special env injection
            mkdir -p ~/.config/plasma-workspace/env
            echo -e "#!/data/data/com.termux/files/usr/bin/bash\nexport XDG_DATA_DIRS=/data/data/com.termux/files/usr/share:\${XDG_DATA_DIRS}\nexport XDG_CONFIG_DIRS=/data/data/com.termux/files/usr/etc/xdg:\${XDG_CONFIG_DIRS}" > ~/.config/plasma-workspace/env/xdg_fix.sh
            chmod +x ~/.config/plasma-workspace/env/xdg_fix.sh
            echo -e "  [+] KDE Plasma XDG environment fixed."
            ;;
    esac

    # GPU & Environment Config (remains mostly same, but ensures XDG vars are sourced by xstartup)
    cat > ~/.config/linux-gpu.sh << EOF
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLES_VERSION_OVERRIDE=3.2
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export MESA_VK_WSI_PRESENT_MODE=immediate
export ZINK_DESCRIPTORS=lazy

# Ensure XDG variables are set for applications
export XDG_DATA_DIRS=/data/data/com.termux/files/usr/share:\${XDG_DATA_DIRS}
export XDG_CONFIG_DIRS=/data/data/com.termux/files/usr/etc/xdg:\${XDG_CONFIG_DIRS}
EOF
    if [ "$DE_CHOICE" == "4" ]; then
        echo "export KWIN_COMPOSE=O2ES" >> ~/.config/linux-gpu.sh
    fi
    echo -e "  [+] GPU and XDG environment variables configured."

    # Create Plank autostart if XFCE or MATE
    if [ "$DE_CHOICE" == "1" ] || [ "$DE_CHOICE" == "3" ]; then
        mkdir -p ~/.config/autostart
        cat > ~/.config/autostart/plank.desktop << 'PLANKEOF'
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank
PLANKEOF
    else
        rm -f ~/.config/autostart/plank.desktop 2>/dev/null
    fi
    echo -e "  [+] Plank autostart configured (if applicable)."

}

# ============== STEP 12: CREATE LAUNCHERS ==============
step_launchers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Configuring Startup Scripts...${NC}"
    echo ""

    # Main Launcher
    cat > ~/start-linux.sh << LAUNCHEREOF
#!/data/data/com.termux/files/usr/bin/bash
echo ""
echo "${CYAN}[*] Starting ${DE_NAME} VNC Server...${NC}"
echo ""

echo "[*] Cleaning up old VNC/PulseAudio sessions..."
vncserver -kill ${VNC_DISPLAY} > /dev/null 2>&1
pulseaudio --kill > /dev/null 2>&1
sleep 1

echo "[*] Starting PulseAudio server..."
pulseaudio --start --exit-idle-time=-1 &
export PULSE_SERVER=127.0.0.1
sleep 1

echo "[*] Starting VNC server on ${VNC_DISPLAY} (Port ${VNC_PORT})..."
vncserver ${VNC_DISPLAY} -geometry 1280x720 -depth 24 -rfbport ${VNC_PORT} -fg
LAUNCHEREOF
    chmod +x ~/start-linux.sh
    echo -e "  [+] Created ~/start-linux.sh"
    
    # Stopper
    cat > ~/stop-linux.sh << STOPEOF
#!/data/data/com.termux/files/usr/bin/bash
echo "${CYAN}[*] Stopping ${DE_NAME} VNC Server...${NC}"
vncserver -kill ${VNC_DISPLAY} > /dev/null 2>&1
pulseaudio --kill > /dev/null 2>/dev/null
echo "${GREEN}[+] Desktop stopped.${NC}"
STOPEOF
    chmod +x ~/stop-linux.sh
    echo -e "  [+] Created ~/stop-linux.sh"
}

# ============== STEP 13: CREATE SHORTCUTS ==============
step_shortcuts() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Creating Desktop Shortcuts...${NC}"
    echo ""
    mkdir -p ~/Desktop
    
    # App shortcuts
    cat > ~/Desktop/Firefox.desktop << 'EOF'
[Desktop Entry]
Name=Firefox
Exec=firefox
Icon=firefox
Type=Application
EOF

    cat > ~/Desktop/VLC.desktop << 'EOF'
[Desktop Entry]
Name=VLC Media Player
Exec=vlc
Icon=vlc
Type=Application
EOF

    cat > ~/Desktop/Wine_Config.desktop << 'EOF'
[Desktop Entry]
Name=Wine Config (Windows)
Exec=wine winecfg
Icon=wine
Type=Application
EOF

    cat > ~/Desktop/Neofetch.desktop << 'EOF'
[Desktop Entry]
Name=Neofetch
Exec=xfce4-terminal -e "neofetch"
Icon=utilities-terminal
Type=Application
EOF

    # Dynamic terminal shortcut
    local term_cmd="xfce4-terminal"
    local term_icon="utilities-terminal"
    if [ "$DE_CHOICE" == "2" ]; then term_cmd="qterminal"; fi
    if [ "$DE_CHOICE" == "3" ]; then term_cmd="mate-terminal"; fi
    if [ "$DE_CHOICE" == "4" ]; then term_cmd="konsole"; fi
    
    cat > ~/Desktop/Terminal.desktop << EOF
[Desktop Entry]
Name=Terminal
Exec=${term_cmd}
Icon=${term_icon}
Type=Application
EOF

    chmod +x ~/Desktop/*.desktop 2>/dev/null
    echo -e "  [+] Added Firefox, VLC, Wine, Neofetch, and Terminal shortcuts."
}

# ============== COMPLETION ==============
show_completion() {
    echo ""
    echo -e "${GREEN}"
    cat << 'COMPLETE'
    ---------------------------------------------------------------
             [*]  INSTALLATION COMPLETE!  [*]                      
    ---------------------------------------------------------------
COMPLETE
    echo -e "${NC}"
    
    echo -e "${WHITE}[*] Your ${DE_NAME} environment is ready via VNC.${NC}"
    echo -e "${CYAN}[*] Installed Software:${NC}"
    echo "    - Python (Flask Demo located in ~/demo_python)"
    echo "    - Firefox Browser & VLC Media Player"
    echo "    - Wine & Hangover (Windows PC App compatibility)"
    echo "    - GPU Hardware Acceleration Enabled (will depend on VNC client for rendering)"
    echo "    - Neofetch for system info"
    echo ""
    echo -e "${YELLOW}------------------------------------------------------------${NC}"
    echo -e "${WHITE}[*] TO START THE DESKTOP:${NC}  ${GREEN}./start-linux.sh${NC}"
    echo -e "${WHITE}[*] TO STOP THE DESKTOP:${NC}   ${GREEN}./stop-linux.sh${NC}"
    echo -e "${YELLOW}------------------------------------------------------------${NC}"
    echo ""
    echo -e "${CYAN}[!] IMPORTANT: To connect to your Linux desktop, download a VNC client app (e.g., VNC Viewer) on your Android device.${NC}"
    echo -e "${CYAN}    Connect to IP address ${WHITE}127.0.0.1${NC} and Port ${WHITE}${VNC_PORT}${NC} with the password you set during installation.${NC}"
    echo -e "${CYAN}    If connecting from another device on your network, use your Android device's local IP address (e.g., 192.168.1.100).${NC}"
    echo ""
}

# ============== MAIN ==============
main() {
    set -e # Exit immediately if a command exits with a non-zero status.

    show_banner
    setup_environment
    
    step_prereq_checks
    step_update
    step_repos
    step_vnc # VNC specific step
    step_desktop
    step_gpu
    step_audio
    step_apps
    step_python
    step_wine
    step_de_config_vnc # Desktop config for VNC
    step_launchers
    step_shortcuts
    
    show_completion
}

main