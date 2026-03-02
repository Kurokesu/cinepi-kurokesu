#!/usr/bin/bash
#
# kurokesu-cinepi installer
# Installs CinePI camera platform on a fresh Raspberry Pi OS (Trixie, 64-bit)
#
# Usage:
#   git clone https://github.com/Kurokesu/kurokesu-cinepi.git
#   cd kurokesu-cinepi
#   ./install.sh
#
# Requirements:
#   - Raspberry Pi 5
#   - Raspberry Pi OS Trixie (64-bit, Debian 13)
#   - CSI-2 camera module connected
#   - Internet connection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/install.log"

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
}

install_dependencies() {
    header "Installing dependencies"

    log "Updating package lists..."
    sudo apt-get update

    log "Installing build tools..."
    sudo apt-get install -y \
        build-essential cmake pkg-config git

    log "Installing Qt6..."
    sudo apt-get install -y \
        qt6-base-dev qt6-declarative-dev \
        qml6-module-qtquick qml6-module-qtquick-controls \
        qml6-module-qtquick-layouts qml6-module-qtquick-window \
        qt6-wayland qt6-shader-baker

    log "Installing rpicam-apps library..."
    sudo apt-get install -y librpicam-app-dev

    log "Installing camera backend dependencies..."
    sudo apt-get install -y \
        libboost-dev libboost-program-options-dev \
        libjpeg-dev libtiff-dev \
        libspdlog-dev libjsoncpp-dev \
        libasound2-dev libudev-dev

    log "All dependencies installed."
}

build_cinepi() {
    header "Building CinePI (release)"
    "$SCRIPT_DIR/scripts/build.sh" release
    log "CinePI built at $SCRIPT_DIR/build/release/cinepi"
}

install_service() {
    header "Installing systemd service"

    # Remove legacy services
    sudo systemctl stop cinepi-raw.service 2>/dev/null || true
    sudo systemctl stop cinepi-qt.service 2>/dev/null || true
    sudo systemctl stop cinepi.service 2>/dev/null || true
    sudo systemctl disable cinepi-raw.service 2>/dev/null || true
    sudo systemctl disable cinepi-qt.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/cinepi-raw.service
    sudo rm -f /etc/systemd/system/cinepi-qt.service

    sudo cp "$SCRIPT_DIR/config/cinepi.service" /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable cinepi.service

    log "cinepi.service installed and enabled."
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
                echo "UUID=$UUID /media/RAW exfat defaults,nofail,uid=$(id -u),gid=$(id -g) 0 0" | sudo tee -a /etc/fstab > /dev/null
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

    sudo systemctl disable NetworkManager-wait-online.service 2>/dev/null || true
    sudo systemctl disable ModemManager.service 2>/dev/null || true
    sudo systemctl disable bluetooth.service 2>/dev/null || true
    sudo systemctl disable cups.service 2>/dev/null || true

    CMDLINE="/boot/firmware/cmdline.txt"
    if [ -f "$CMDLINE" ]; then
        if ! grep -q "loglevel=0" "$CMDLINE"; then
            sudo sed -i 's/\bquiet\b/quiet loglevel=0 systemd.show_status=false/' "$CMDLINE"
            log "Suppressed boot messages"
        fi
        if ! grep -q "logo.nologo" "$CMDLINE"; then
            sudo sed -i 's/$/ logo.nologo vt.global_cursor_default=0/' "$CMDLINE"
            log "Disabled boot logo and cursor"
        fi
    fi

    touch "$HOME/.hushlogin"

    GETTY_DIR="/etc/systemd/system/getty@tty1.service.d"
    if [ -d "$GETTY_DIR" ]; then
        sudo bash -c "cat > $GETTY_DIR/autologin.conf << 'GETTYEOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noissue --skip-login --noclear %I \$TERM
GETTYEOF"
        log "Configured silent autologin"
    fi

    if ! grep -q "tty1.*clear" "$HOME/.profile" 2>/dev/null; then
        cat >> "$HOME/.profile" << 'PROFILE_EOF'

if [ "$(tty)" = "/dev/tty1" ]; then
    clear
fi
PROFILE_EOF
        log "Added tty1 clear to .profile"
    fi

    sudo systemctl daemon-reload
    log "Boot optimizations applied."
}

install_splash() {
    header "Installing splash screen"

    SPLASH_SRC="$SCRIPT_DIR/splash.png"
    SPLASH_DST="/usr/share/plymouth/themes/pix/splash.png"

    if [ ! -f "$SPLASH_SRC" ]; then
        warn "splash.png not found, skipping"
        return
    fi
    if [ ! -d "/usr/share/plymouth/themes/pix" ]; then
        warn "Plymouth pix theme not found, skipping"
        return
    fi

    if [ -f "$SPLASH_DST" ] && [ ! -f "${SPLASH_DST}.bak" ]; then
        sudo cp "$SPLASH_DST" "${SPLASH_DST}.bak"
    fi

    sudo cp "$SPLASH_SRC" "$SPLASH_DST"
    log "Installed splash image"

    sudo plymouth-set-default-theme --rebuild-initrd pix
    log "Plymouth splash updated."
}

hide_cursor() {
    header "Hiding mouse cursor"

    # Disable hardware cursor at the compositor level
    LABWC_ENV="$HOME/.config/labwc/environment"
    mkdir -p "$(dirname "$LABWC_ENV")"
    for VAR in "WLR_NO_HARDWARE_CURSORS=1"; do
        KEY="${VAR%%=*}"
        if ! grep -q "$KEY" "$LABWC_ENV" 2>/dev/null; then
            echo "$VAR" >> "$LABWC_ENV"
        fi
    done
    log "Disabled hardware cursor in labwc environment"

    log "Mouse cursor hidden."
}

print_summary() {
    header "Installation Complete"

    echo -e "${GREEN}kurokesu-cinepi installed successfully!${NC}"
    echo ""
    echo "Binary:  $SCRIPT_DIR/build/release/cinepi"
    echo "Service: cinepi.service (starts on boot)"
    echo ""
    echo "Quick start:"
    echo "  sudo reboot                           # auto-starts on boot"
    echo "  ./scripts/run-cinepi.sh               # manual start"
    echo "  ./scripts/stop-cinepi.sh              # stop"
    echo "  ./scripts/build.sh debug              # rebuild (debug)"
    echo "  ./scripts/build.sh release            # rebuild (release)"
    echo ""
    echo "Sensor config: edit /boot/firmware/config.txt"
    echo "  camera_auto_detect=0"
    echo "  dtoverlay=imx283"
    echo ""
    echo -e "Install log: ${CYAN}$LOG_FILE${NC}"
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
hide_cursor
print_summary
