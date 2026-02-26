#!/usr/bin/bash
#
# kurokesu-cinepi installer
# Installs CinePI camera platform on a fresh Raspberry Pi OS (Trixie, 64-bit)
#
# Usage:
#   git clone --recurse-submodules https://github.com/Kurokesu/kurokesu-cinepi.git
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

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[kurokesu-cinepi]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
    exit 1
}

header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# Check we're running on a Raspberry Pi
check_platform() {
    header "Checking platform"

    if [ ! -f /proc/device-tree/model ]; then
        warn "Cannot detect board model. Continuing anyway..."
        return
    fi

    MODEL=$(tr -d '\0' < /proc/device-tree/model)
    log "Detected: $MODEL"

    if [[ ! "$MODEL" == *"Raspberry Pi"* ]]; then
        warn "This doesn't appear to be a Raspberry Pi. Continuing anyway..."
    fi

    # Check 64-bit
    ARCH=$(uname -m)
    if [ "$ARCH" != "aarch64" ]; then
        error "64-bit OS required (detected: $ARCH). Please use Raspberry Pi OS 64-bit."
    fi
    log "Architecture: $ARCH"

    # Check Bookworm
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        log "OS: $PRETTY_NAME"
    fi
}

# Install system dependencies
install_dependencies() {
    header "Installing system dependencies"

    log "Updating package lists..."
    sudo apt-get update

    log "Installing build tools..."
    sudo apt-get install -y \
        build-essential \
        cmake \
        meson \
        ninja-build \
        pkg-config \
        git

    log "Installing Qt 6 development packages..."
    sudo apt-get install -y \
        qt6-base-dev \
        qt6-declarative-dev \
        qml6-module-qtquick \
        qml6-module-qtquick-controls \
        qml6-module-qtquick-layouts \
        qml6-module-qtquick-window \
        qt6-wayland

    log "Installing rpicam-apps library (system libcamera + rpicam-apps)..."
    sudo apt-get install -y \
        librpicam-app-dev

    log "Installing Redis..."
    sudo apt-get install -y \
        redis-server \
        libhiredis-dev

    log "Installing cinepi-raw build dependencies..."
    sudo apt-get install -y \
        libboost-dev \
        libboost-program-options-dev \
        libjpeg-dev \
        libtiff-dev \
        libspdlog-dev \
        libjsoncpp-dev \
        libasound2-dev \
        libudev-dev

    log "Installing kernel driver build dependencies..."
    sudo apt-get install -y --no-install-recommends \
        dkms

    log "All apt dependencies installed."

    # Build and install redis-plus-plus (not packaged in Debian)
    if ! pkg-config --exists redis++ 2>/dev/null; then
        log "Building redis-plus-plus from source..."
        REDIS_PP_DIR=$(mktemp -d)
        git clone --depth 1 https://github.com/sewenew/redis-plus-plus.git "$REDIS_PP_DIR"
        cd "$REDIS_PP_DIR"
        mkdir build && cd build
        cmake -DCMAKE_BUILD_TYPE=Release \
              -DREDIS_PLUS_PLUS_CXX_STANDARD=17 \
              -DREDIS_PLUS_PLUS_BUILD_TEST=OFF ..
        make -j$(nproc)
        sudo make install
        cd "$SCRIPT_DIR"
        rm -rf "$REDIS_PP_DIR"
        sudo ldconfig
        log "redis-plus-plus installed."
    else
        log "redis-plus-plus already installed, skipping."
    fi

    # Install cpp-mjpeg-streamer (header-only, not packaged in Debian)
    if ! pkg-config --exists nadjieb_mjpeg_streamer 2>/dev/null; then
        log "Installing cpp-mjpeg-streamer (header-only)..."
        MJPEG_DIR=$(mktemp -d)
        git clone --depth 1 https://github.com/nadjieb/cpp-mjpeg-streamer.git "$MJPEG_DIR"
        cd "$MJPEG_DIR"
        mkdir build && cd build
        cmake -DCMAKE_BUILD_TYPE=Release ..
        sudo make install
        cd "$SCRIPT_DIR"
        rm -rf "$MJPEG_DIR"
        log "cpp-mjpeg-streamer installed."
    else
        log "cpp-mjpeg-streamer already installed, skipping."
    fi
}

# Enable Redis service
setup_redis() {
    header "Setting up Redis"

    sudo systemctl enable redis-server
    sudo systemctl start redis-server
    log "Redis server enabled and started."
}

# Build cinepi-raw
build_cinepi_raw() {
    header "Building cinepi-raw"

    CINEPI_RAW_DIR="$SCRIPT_DIR/cinepi-raw"

    if [ ! -d "$CINEPI_RAW_DIR" ]; then
        error "cinepi-raw directory not found."
    fi

    cd "$CINEPI_RAW_DIR"

    # Clean previous build if exists
    if [ -d "build" ]; then
        log "Cleaning previous build..."
        rm -rf build
    fi

    log "Configuring with Meson..."
    meson setup build --buildtype=release

    log "Building..."
    ninja -C build

    cd "$SCRIPT_DIR"
    sudo ldconfig
    log "cinepi-raw built at $CINEPI_RAW_DIR/build/cinepi/cinepi-raw"
}

# Build cinepi-qt GUI
build_cinepi_qt() {
    header "Building cinepi-qt GUI"

    CINEPI_QT_DIR="$SCRIPT_DIR/cinepi-qt"

    cd "$CINEPI_QT_DIR"

    # Clean previous build if exists
    if [ -d "build" ]; then
        log "Cleaning previous build..."
        rm -rf build
    fi

    mkdir -p build
    cd build

    log "Configuring with CMake..."
    cmake .. -DCMAKE_BUILD_TYPE=Release

    log "Building..."
    make -j$(nproc)

    cd "$SCRIPT_DIR"
    log "cinepi-qt built at $CINEPI_QT_DIR/build/cinepi-qt"
}

# Install configuration files
install_config() {
    header "Installing configuration"

    # Copy default config files to home directory (where the app expects them)
    if [ ! -f "$HOME/config.ini" ]; then
        cp "$SCRIPT_DIR/config/config.ini" "$HOME/config.ini"
        log "Installed default config.ini"
    else
        log "config.ini already exists, skipping"
    fi

    if [ ! -f "$HOME/overlay.ini" ]; then
        cp "$SCRIPT_DIR/config/overlay.ini" "$HOME/overlay.ini"
        log "Installed default overlay.ini"
    else
        log "overlay.ini already exists, skipping"
    fi

    # Make scripts executable
    chmod +x "$SCRIPT_DIR/scripts/"*.sh

    log "Configuration installed."
}

# Install systemd services
install_services() {
    header "Installing systemd services"

    # Stop existing services if running
    sudo systemctl stop cinepi-raw.service 2>/dev/null || true
    sudo systemctl stop cinepi-qt.service 2>/dev/null || true

    # Disable and remove legacy service names
    sudo systemctl stop run-raw.service 2>/dev/null || true
    sudo systemctl disable run-raw.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/run-raw.service 2>/dev/null || true

    # Install service files
    sudo cp "$SCRIPT_DIR/config/cinepi-raw.service" /etc/systemd/system/
    sudo cp "$SCRIPT_DIR/config/cinepi-qt.service" /etc/systemd/system/

    sudo systemctl daemon-reload

    sudo systemctl enable cinepi-raw.service
    sudo systemctl enable cinepi-qt.service

    log "Systemd services installed and enabled."
    log "Services will start on next boot, or start manually with:"
    log "  sudo systemctl start cinepi-raw"
    log "  sudo systemctl start cinepi-qt"
}

# Set up NVMe storage mount point
setup_storage() {
    header "Setting up storage"

    # Create RAW recording directory
    sudo mkdir -p /media/RAW

    # Check if NVMe is present
    if lsblk | grep -q "nvme"; then
        log "NVMe drive detected."

        # Check if already mounted
        if mountpoint -q /media/RAW 2>/dev/null; then
            log "/media/RAW is already mounted."
        else
            # Find NVMe partition
            NVME_PART=$(lsblk -lnp -o NAME,TYPE | grep "nvme.*part" | head -1 | awk '{print $1}')
            if [ -n "$NVME_PART" ]; then
                log "Found NVMe partition: $NVME_PART"

                # Check if fstab entry exists
                if ! grep -q "/media/RAW" /etc/fstab; then
                    # Get UUID
                    UUID=$(sudo blkid -s UUID -o value "$NVME_PART" 2>/dev/null || echo "")
                    if [ -n "$UUID" ]; then
                        echo "UUID=$UUID /media/RAW exfat defaults,nofail,uid=$(id -u),gid=$(id -g) 0 0" | sudo tee -a /etc/fstab > /dev/null
                        log "Added fstab entry for NVMe ($UUID)"
                        sudo mount /media/RAW || warn "Could not mount NVMe. You may need to format it first."
                    fi
                fi
            fi
        fi
    else
        warn "No NVMe drive detected. RAW files will be written to /media/RAW."
        warn "For best performance, connect an NVMe SSD via the PCIe connector."
    fi
}

# Install sensor drivers via DKMS (optional)
install_drivers() {
    header "Installing sensor drivers"

    echo ""
    echo "Available sensor drivers:"
    echo "  1) IMX283 (Kurokesu C1-IMX283)"
    echo "  2) IMX585 (Kurokesu C1-IMX585)"
    echo "  3) Both"
    echo "  4) Skip (use built-in sensor support)"
    echo ""
    read -p "Select driver to install [4]: " DRIVER_CHOICE
    DRIVER_CHOICE=${DRIVER_CHOICE:-4}

    case $DRIVER_CHOICE in
        1|3)
            log "Installing IMX283 driver..."
            cd "$SCRIPT_DIR/drivers/imx283-v4l2-driver"
            bash setup.sh
            log "IMX283 driver installed."
            ;;&
        2|3)
            log "Installing IMX585 driver..."
            cd "$SCRIPT_DIR/drivers/imx585-v4l2-driver"
            bash setup.sh
            log "IMX585 driver installed."
            ;;
        4)
            log "Skipping driver installation."
            ;;
        *)
            warn "Invalid choice, skipping driver installation."
            ;;
    esac

    cd "$SCRIPT_DIR"
}

# Optimize boot experience
optimize_boot() {
    header "Optimizing boot"

    # Disable unnecessary services for a camera appliance
    log "Disabling unnecessary services..."
    sudo systemctl disable NetworkManager-wait-online.service 2>/dev/null || true
    sudo systemctl disable ModemManager.service 2>/dev/null || true
    sudo systemctl disable bluetooth.service 2>/dev/null || true
    sudo systemctl disable cups.service 2>/dev/null || true
    sudo systemctl disable e2scrub_reap.service 2>/dev/null || true

    # Suppress boot text on console
    CMDLINE="/boot/firmware/cmdline.txt"
    if [ -f "$CMDLINE" ]; then
        # Add loglevel=0 if not present
        if ! grep -q "loglevel=0" "$CMDLINE"; then
            sudo sed -i 's/\bquiet\b/quiet loglevel=0 systemd.show_status=false/' "$CMDLINE"
            log "Suppressed kernel and systemd boot messages"
        fi
        # Add logo.nologo if not present
        if ! grep -q "logo.nologo" "$CMDLINE"; then
            sudo sed -i 's/$/ logo.nologo vt.global_cursor_default=0/' "$CMDLINE"
            log "Disabled boot logo and cursor"
        fi
    fi

    # Suppress login banner on tty1
    touch "$HOME/.hushlogin"
    log "Created .hushlogin to suppress login banner"

    # Suppress login text on getty (hostname banner, login prompt)
    GETTY_DIR="/etc/systemd/system/getty@tty1.service.d"
    if [ -d "$GETTY_DIR" ]; then
        sudo bash -c "cat > $GETTY_DIR/autologin.conf << 'GETTYEOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noissue --skip-login --noclear %I \$TERM
GETTYEOF"
        log "Configured silent getty autologin"
    fi

    # Clear tty1 screen on login (hides any remaining text before GUI starts)
    if ! grep -q "tty1.*clear" "$HOME/.profile" 2>/dev/null; then
        cat >> "$HOME/.profile" << 'PROFILE_EOF'

# Clear console on tty1 to hide boot text before GUI starts
if [ "$(tty)" = "/dev/tty1" ]; then
    clear
fi
PROFILE_EOF
        log "Added tty1 clear to .profile"
    fi

    sudo systemctl daemon-reload
    log "Boot optimizations applied."
}

# Install custom Plymouth splash screen
install_splash() {
    header "Installing splash screen"

    SPLASH_SRC="$SCRIPT_DIR/splash.png"
    SPLASH_DST="/usr/share/plymouth/themes/pix/splash.png"

    if [ ! -f "$SPLASH_SRC" ]; then
        warn "splash.png not found in project, skipping splash install"
        return
    fi

    if [ ! -d "/usr/share/plymouth/themes/pix" ]; then
        warn "Plymouth pix theme not found, skipping splash install"
        return
    fi

    # Backup original splash if not already backed up
    if [ -f "$SPLASH_DST" ] && [ ! -f "${SPLASH_DST}.bak" ]; then
        sudo cp "$SPLASH_DST" "${SPLASH_DST}.bak"
        log "Backed up original splash"
    fi

    sudo cp "$SPLASH_SRC" "$SPLASH_DST"
    log "Installed Kurokesu splash image"

    # Rebuild initramfs to include new splash
    log "Rebuilding initramfs (this may take a few minutes)..."
    sudo plymouth-set-default-theme --rebuild-initrd pix
    log "Plymouth splash updated."
}

# Hide mouse cursor (kiosk mode — touchscreen only)
hide_cursor() {
    header "Hiding mouse cursor"

    CURSOR_DIR="$HOME/.icons/hidden/cursors"
    mkdir -p "$CURSOR_DIR"

    # Create a 1x1 transparent PNG and convert to X cursor
    python3 -c "
from PIL import Image
img = Image.new('RGBA', (1, 1), (0, 0, 0, 0))
img.save('/tmp/_transparent_cursor.png')
"
    echo "1 0 0 /tmp/_transparent_cursor.png" > /tmp/_transparent_cursor.cfg
    xcursorgen /tmp/_transparent_cursor.cfg "$CURSOR_DIR/left_ptr"
    rm -f /tmp/_transparent_cursor.png /tmp/_transparent_cursor.cfg

    # Create symlinks for all common cursor names
    local CURSOR_NAMES="default top_left_arrow arrow watch hand2 hand1 xterm ibeam crosshair pointer grab grabbing text move"
    for name in $CURSOR_NAMES; do
        [ ! -e "$CURSOR_DIR/$name" ] && ln -s left_ptr "$CURSOR_DIR/$name"
    done

    # Write theme index
    cat > "$HOME/.icons/hidden/cursor.theme" << 'THEME_EOF'
[Icon Theme]
Name=hidden
Comment=Transparent cursor theme for kiosk mode
THEME_EOF

    # Set cursor theme in wayfire config
    WAYFIRE_CFG="$HOME/.config/wayfire.ini"
    if [ -f "$WAYFIRE_CFG" ]; then
        if ! grep -q "cursor_theme" "$WAYFIRE_CFG"; then
            sed -i '/^\[input\]/a cursor_theme = hidden\ncursor_size = 1' "$WAYFIRE_CFG"
            log "Set hidden cursor theme in wayfire.ini"
        fi
    fi

    log "Mouse cursor hidden (transparent cursor theme installed)."
}

# Print summary and next steps
print_summary() {
    header "Installation Complete"

    echo -e "${GREEN}kurokesu-cinepi has been installed successfully!${NC}"
    echo ""
    echo "Installed components:"
    echo "  - cinepi-raw    : $SCRIPT_DIR/cinepi-raw/build/cinepi/cinepi-raw"
    echo "  - cinepi-qt     : $SCRIPT_DIR/cinepi-qt/build/cinepi-qt"
    echo "  - Config files  : ~/config.ini, ~/overlay.ini"
    echo "  - Services      : cinepi-raw.service, cinepi-qt.service"
    echo ""
    echo "Quick start:"
    echo "  # Start services now:"
    echo "  sudo systemctl start cinepi-raw"
    echo "  sudo systemctl start cinepi-qt"
    echo ""
    echo "  # Or reboot (services start automatically):"
    echo "  sudo reboot"
    echo ""
    echo "  # View logs:"
    echo "  journalctl -u cinepi-raw -f"
    echo "  journalctl -u cinepi-qt -f"
    echo ""
    echo "  # Run GUI manually (for debugging):"
    echo "  $SCRIPT_DIR/scripts/run-raw.sh &"
    echo "  $SCRIPT_DIR/scripts/run-qt-gui.sh"
    echo ""
    echo "Camera sensor configuration:"
    echo "  Edit /boot/firmware/config.txt and add the appropriate dtoverlay"
    echo "  for your sensor. Examples:"
    echo "    dtoverlay=imx283"
    echo "    dtoverlay=imx477"
    echo "    dtoverlay=imx585"
    echo ""
    echo "  Tuning files are in: $SCRIPT_DIR/tuning/"
    echo "  Edit $SCRIPT_DIR/scripts/run-raw.sh to change the tuning file."
    echo ""
    echo -e "Full install log: ${CYAN}$LOG_FILE${NC}"
}

# ──────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          kurokesu-cinepi installer           ║${NC}"
echo -e "${CYAN}║   Open-source cinema camera for RPi 5        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Initialize log
echo "=== kurokesu-cinepi install started at $(date) ===" > "$LOG_FILE"

check_platform
install_dependencies
setup_redis
build_cinepi_raw
build_cinepi_qt
install_config
install_services
setup_storage
install_drivers
optimize_boot
install_splash
hide_cursor
print_summary
