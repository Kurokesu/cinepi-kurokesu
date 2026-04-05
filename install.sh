#!/usr/bin/bash
#
# kurokesu-cinepi installer
# Installs CinePI camera platform on a fresh Raspberry Pi OS Lite (Trixie, 64-bit)
#
# Usage:
#   git clone https://github.com/Kurokesu/kurokesu-cinepi.git
#   cd kurokesu-cinepi
#   ./install.sh
#
# Requirements:
#   - Raspberry Pi 5
#   - Raspberry Pi OS Lite Trixie (64-bit, Debian 13)
#   - CSI-2 camera module connected
#   - Internet connection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/install.log"

INSTALL_USER="$(whoami)"
INSTALL_UID="$(id -u)"
INSTALL_HOME="$HOME"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()    { echo -e "${GREEN}[cinepi]${NC} $1"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }
warn()   { echo -e "${YELLOW}[WARNING]${NC} $1"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"; }
error()  { echo -e "${RED}[ERROR]${NC} $1"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"; exit 1; }
header() { echo ""; echo -e "${CYAN}=== $1 ===${NC}"; echo ""; }

check_platform() {
    header "Checking platform"

    if [ -f /proc/device-tree/model ]; then
        MODEL=$(tr -d '\0' < /proc/device-tree/model)
        log "Detected: $MODEL"
    fi

    ARCH=$(uname -m)
    if [ "$ARCH" != "aarch64" ]; then
        error "64-bit OS required (detected: $ARCH)"
    fi
    log "Architecture: $ARCH"

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        log "OS: $PRETTY_NAME"
    fi

    log "Install user: $INSTALL_USER (uid=$INSTALL_UID)"
}

install_dependencies() {
    header "Installing dependencies"

    log "Updating package lists..."
    sudo apt-get update

    log "Installing build tools..."
    sudo apt-get install -y \
        build-essential cmake pkg-config git

    log "Installing Cage kiosk compositor..."
    sudo apt-get install -y cage

    log "Installing Qt6..."
    sudo apt-get install -y \
        qt6-base-dev qt6-declarative-dev \
        qml6-module-qtquick qml6-module-qtquick-controls \
        qml6-module-qtquick-layouts qml6-module-qtquick-window \
        qt6-shader-baker qt6-shadertools-dev

    log "Installing libcamera and rpicam-apps..."
    sudo apt-get install -y libcamera-dev librpicam-app-dev

    log "Installing graphics libraries..."
    sudo apt-get install -y \
        libegl-dev libgles-dev libdrm-dev

    log "Installing camera backend dependencies..."
    sudo apt-get install -y \
        libboost-dev libboost-program-options-dev \
        libjpeg-dev libtiff-dev \
        libexif-dev libpng-dev \
        libspdlog-dev libjsoncpp-dev \
        libasound2-dev libudev-dev

    log "Installing framebuffer tools..."
    sudo apt-get install -y fbi

    log "All dependencies installed."
}

build_cinepi() {
    header "Building CinePI (release)"
    "$SCRIPT_DIR/scripts/build.sh" release
    log "CinePI built at $SCRIPT_DIR/build/release/cinepi"
}

install_service() {
    header "Installing systemd service"

    # Stop and remove any previous versions
    sudo systemctl stop cinepi.service 2>/dev/null || true
    sudo systemctl disable cinepi.service 2>/dev/null || true
    sudo systemctl stop cinepi-raw.service 2>/dev/null || true
    sudo systemctl stop cinepi-qt.service 2>/dev/null || true
    sudo systemctl disable cinepi-raw.service 2>/dev/null || true
    sudo systemctl disable cinepi-qt.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/cinepi-raw.service
    sudo rm -f /etc/systemd/system/cinepi-qt.service

    # Generate service file from template with actual paths
    sed \
        -e "s|CINEPI_USER|$INSTALL_USER|g" \
        -e "s|CINEPI_UID|$INSTALL_UID|g" \
        -e "s|CINEPI_REPO_DIR|$SCRIPT_DIR|g" \
        "$SCRIPT_DIR/scripts/cinepi.service" \
        | sudo tee /etc/systemd/system/cinepi.service > /dev/null

    # Create PAM config for logind session activation (required by Cage)
    sudo tee /etc/pam.d/cinepi > /dev/null <<'PAMEOF'
auth       required pam_unix.so
auth       required pam_env.so
account    required pam_unix.so
session    required pam_unix.so
session    required pam_loginuid.so
session    optional pam_systemd.so
PAMEOF
    log "Created /etc/pam.d/cinepi"

    # Deploy service helper scripts
    sudo cp "$SCRIPT_DIR/scripts/cinepi-chvt.sh" /usr/local/bin/cinepi-chvt.sh
    sudo cp "$SCRIPT_DIR/scripts/cinepi-stop.sh" /usr/local/bin/cinepi-stop.sh
    sudo chmod +x /usr/local/bin/cinepi-chvt.sh /usr/local/bin/cinepi-stop.sh
    log "Installed service helper scripts to /usr/local/bin/"

    sudo systemctl daemon-reload
    sudo systemctl enable cinepi.service

    log "cinepi.service installed and enabled (user=$INSTALL_USER, repo=$SCRIPT_DIR)"
}

setup_storage() {
    header "Setting up storage"

    sudo mkdir -p /media/RAW

    if lsblk | grep -q "nvme"; then
        log "NVMe drive detected."
        NVME_PART=$(lsblk -lnp -o NAME,TYPE | grep "nvme.*part" | head -1 | awk '{print $1}')
        if [ -n "$NVME_PART" ] && ! grep -q "/media/RAW" /etc/fstab; then
            UUID=$(sudo blkid -s UUID -o value "$NVME_PART" 2>/dev/null || echo "")
            if [ -n "$UUID" ]; then
                echo "UUID=$UUID /media/RAW exfat defaults,nofail,uid=$INSTALL_UID,gid=$(id -g) 0 0" | sudo tee -a /etc/fstab > /dev/null
                log "Added fstab entry for NVMe ($UUID)"
                sudo mount /media/RAW || warn "Could not mount NVMe. Format it first if needed."
            fi
        fi
    else
        warn "No NVMe detected. Recording to /media/RAW requires external storage."
    fi
}

optimize_boot() {
    header "Optimizing boot"

    # ── Disable unnecessary services ──
    local DISABLE_SERVICES=(
        NetworkManager-wait-online.service
        ModemManager.service
        bluetooth.service
        cups.service
        triggerhappy.service
        apt-daily.service
        apt-daily-upgrade.service
    )
    for svc in "${DISABLE_SERVICES[@]}"; do
        sudo systemctl disable "$svc" 2>/dev/null || true
    done
    log "Disabled ${#DISABLE_SERVICES[@]} unnecessary services"

    # ── Disable unnecessary timers ──
    local DISABLE_TIMERS=(
        man-db.timer
        apt-daily.timer
        apt-daily-upgrade.timer
        e2scrub_all.timer
    )
    for tmr in "${DISABLE_TIMERS[@]}"; do
        sudo systemctl disable "$tmr" 2>/dev/null || true
    done
    log "Disabled ${#DISABLE_TIMERS[@]} unnecessary timers"

    # ── Firmware config ──
    CONFIG_TXT="/boot/firmware/config.txt"
    if [ -f "$CONFIG_TXT" ]; then
        add_config_line() {
            if ! grep -q "^$1" "$CONFIG_TXT"; then
                echo "$1" | sudo tee -a "$CONFIG_TXT" > /dev/null
                log "Added $1 to config.txt"
            fi
        }
        add_config_line "disable_splash=1"
        add_config_line "boot_delay=0"
        add_config_line "dtparam=audio=off"
        add_config_line "dtoverlay=disable-bt"
        add_config_line "dtoverlay=disable-wifi"
    fi

    # ── Kernel command line ──
    CMDLINE="/boot/firmware/cmdline.txt"
    if [ -f "$CMDLINE" ]; then
        CMDLINE_CONTENT=$(cat "$CMDLINE")
        CMDLINE_ADDITIONS=""

        # Redirect console to unused tty (tty12 is never displayed)
        if grep -q "console=tty1" "$CMDLINE"; then
            sudo sed -i 's|console=tty1|console=tty12|' "$CMDLINE"
            log "Redirected console from tty1 to tty12"
        fi

        for param in "loglevel=0" "systemd.show_status=false" "systemd.log_level=3" "logo.nologo" "vt.global_cursor_default=0" "consoleblank=1"; do
            if ! echo "$CMDLINE_CONTENT" | grep -q "$param"; then
                CMDLINE_ADDITIONS="$CMDLINE_ADDITIONS $param"
            fi
        done

        if [ -n "$CMDLINE_ADDITIONS" ]; then
            sudo sed -i "s|$|$CMDLINE_ADDITIONS|" "$CMDLINE"
            log "Added kernel params:$CMDLINE_ADDITIONS"
        fi

        # Ensure 'quiet' is present
        if ! echo "$CMDLINE_CONTENT" | grep -q "quiet"; then
            sudo sed -i 's|$| quiet|' "$CMDLINE"
            log "Added 'quiet' to cmdline"
        fi
    fi

    # ── Silent console ──
    touch "$INSTALL_HOME/.hushlogin"

    # ── Disable login prompt on display TTY ──
    sudo systemctl disable getty@tty1.service 2>/dev/null || true
    sudo systemctl mask getty@tty1.service 2>/dev/null || true
    log "Masked getty@tty1 (no login prompt on display)"

    sudo systemctl daemon-reload
    log "Boot optimizations applied."
}

install_splash() {
    header "Installing splash screen"

    SPLASH_SRC="$SCRIPT_DIR/splash.png"

    if [ ! -f "$SPLASH_SRC" ]; then
        warn "splash.png not found in repo, skipping splash install"
        return
    fi

    # Install splash service (fbi-based framebuffer splash)
    sed \
        -e "s|CINEPI_REPO_DIR|$SCRIPT_DIR|g" \
        "$SCRIPT_DIR/scripts/cinepi-splash.service" \
        | sudo tee /etc/systemd/system/cinepi-splash.service > /dev/null

    sudo systemctl daemon-reload
    sudo systemctl enable cinepi-splash.service

    # Suppress systemd status messages on console
    sudo mkdir -p /etc/systemd/system.conf.d
    sudo tee /etc/systemd/system.conf.d/quiet.conf > /dev/null <<'QUIETEOF'
[Manager]
ShowStatus=no
QUIETEOF

    log "Splash screen configured (fbi on framebuffer)."
}

print_summary() {
    header "Installation Complete"

    echo -e "${GREEN}kurokesu-cinepi installed successfully!${NC}"
    echo ""
    echo "User:    $INSTALL_USER"
    echo "Binary:  $SCRIPT_DIR/build/release/cinepi"
    echo "Service: cinepi.service (Cage kiosk → auto-starts on boot)"
    echo ""
    echo "Quick start:"
    echo "  sudo reboot                           # auto-starts on boot"
    echo "  ./scripts/run.sh                      # manual start (dev)"
    echo "  ./scripts/stop.sh                     # stop"
    echo "  ./scripts/build.sh debug              # rebuild (debug)"
    echo "  ./scripts/build.sh release            # rebuild (release)"
    echo ""
    echo "Sensor config: edit /boot/firmware/config.txt"
    echo "  camera_auto_detect=0"
    echo "  dtoverlay=imx283"
    echo ""
    echo -e "Boot analysis:  ${CYAN}systemd-analyze blame${NC}"
    echo -e "Install log:    ${CYAN}$LOG_FILE${NC}"
}

# ── Main ──────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          kurokesu-cinepi installer           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

echo "=== kurokesu-cinepi install started at $(date) ===" > "$LOG_FILE"

check_platform
install_dependencies
build_cinepi
install_service
setup_storage
optimize_boot
install_splash
print_summary
