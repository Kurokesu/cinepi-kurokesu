# kurokesu-cinepi

Open-source cinema camera platform for Raspberry Pi 5 with Qt Quick GUI, CinemaDNG RAW recording, and Kurokesu CSI-2 sensor support.

This project is a fork and evolution of the [CinePI](https://github.com/cinepi/cinepi-sdk) platform, replacing the original ImGui-based GUI with a modern Qt Quick (QML) interface while preserving the powerful cinepi-raw recording backend.

## Features

- **12-bit CinemaDNG RAW recording** to NVMe SSD via PCIe
- **Qt Quick GUI** with touch-friendly controls optimized for HyperPixel 4 Square display
- **Live camera preview** via shared memory (zero-copy) with MJPEG fallback
- **GPU-accelerated overlays**: zebra (overexposure), false color, focus peaking, grayscale
- **Composition guides**: rule of thirds, center crosshair, cinematic aspect ratios (16:9, 1.85:1, 4:3)
- **Camera controls**: ISO, shutter angle, FPS, white balance, compression, color gains
- **Redis-based IPC** between backend and GUI
- **Kurokesu sensor support**: IMX283, IMX585, IMX477, IMX462 with DKMS drivers
- **Systemd services** for automatic startup

## Hardware Requirements

| Component | Requirement |
|-----------|-------------|
| Board | Raspberry Pi 5 (4GB+ RAM recommended) |
| OS | Raspberry Pi OS Bookworm (64-bit) |
| Camera | MIPI CSI-2 module (Kurokesu IMX283/IMX585/IMX477 or compatible) |
| Storage | NVMe SSD via PCIe HAT (for RAW recording) |
| Display | HyperPixel 4 Square (720x720) or any HDMI/DSI display |

## Quick Start

### 1. Clone the repository

```bash
git clone --recursive https://github.com/kurokesu/kurokesu-cinepi.git
cd kurokesu-cinepi
```

### 2. Run the installer

```bash
chmod +x install.sh
./install.sh
```

The installer will:
- Install all system dependencies (Qt5, Redis, libcamera, build tools)
- Build cinepi-raw (camera backend)
- Build cinepi-qt (Qt Quick GUI)
- Install default configuration files
- Set up systemd services for automatic startup
- Configure NVMe storage mount
- Optionally install sensor-specific kernel drivers

### 3. Configure your sensor

Edit `/boot/firmware/config.txt` and add the overlay for your camera:

```ini
# Disable automatic camera detection
camera_auto_detect=0

# Enable your sensor (uncomment one):
dtoverlay=imx283
#dtoverlay=imx477
#dtoverlay=imx585
#dtoverlay=imx462,clock-frequency=37125000
```

Reboot after making changes.

### 4. Start the camera

```bash
# Services start automatically on boot, or start manually:
sudo systemctl start cinepi-raw
sudo systemctl start cinepi-qt
```

## Project Structure

```
kurokesu-cinepi/
├── cinepi-raw/              # Camera backend (git submodule)
│   ├── cinepi/              #   CinePI-specific code (DNG encoder, MJPEG, Redis)
│   ├── core/                #   rpicam-apps core framework
│   ├── encoder/             #   Video encoders (MJPEG, H.264, libav)
│   ├── preview/             #   Preview backends (DRM, EGL, Qt)
│   └── meson.build
├── cinepi-qt/               # Qt Quick GUI (this project)
│   ├── src/                 #   C++ source files
│   │   ├── main.cpp         #     Application entry point
│   │   ├── redisbridge.*    #     Redis ↔ QML bridge
│   │   ├── mjpegclient.*    #     MJPEG stream client
│   │   ├── frameprovider.*  #     QML image provider
│   │   ├── configmanager.*  #     INI config reader/writer
│   │   └── sharedmempreview.* #   Zero-copy shared memory preview
│   ├── qml/                 #   QML UI files
│   │   ├── main.qml         #     Main window
│   │   ├── CameraPreview.qml
│   │   ├── CameraControls.qml
│   │   ├── ShaderOverlays.qml
│   │   ├── GridOverlays.qml
│   │   ├── StatusBar.qml
│   │   └── SettingsPanel.qml
│   ├── shaders/             #   GLSL fragment shaders
│   │   ├── zebra.frag
│   │   ├── falsecolor.frag
│   │   └── focuspeaking.frag
│   ├── CMakeLists.txt
│   └── qml.qrc
├── config/                  # Configuration files
│   ├── config.ini           #   Overlay settings defaults
│   ├── overlay.ini          #   Grid/guide settings defaults
│   ├── post-processing.json #   cinepi-raw post-processing pipeline
│   ├── cinepi-raw.service   #   Systemd service for backend
│   └── cinepi-qt.service    #   Systemd service for GUI
├── scripts/                 # Launch scripts
│   ├── run-raw.sh           #   Backend launcher (configurable via env vars)
│   └── run-qt-gui.sh        #   GUI launcher
├── drivers/                 # Kernel sensor drivers (DKMS)
│   ├── imx283-v4l2-driver/
│   └── imx585-v4l2-driver/
├── tuning/                  # Sensor tuning files (libcamera)
│   ├── imx283.json
│   └── imx477.json
├── install.sh               # One-step installer
└── README.md
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      cinepi-qt (GUI)                        │
│  ┌──────────┐  ┌────────────┐  ┌─────────────────────────┐ │
│  │ Camera   │  │ Shader     │  │ Camera Controls         │ │
│  │ Preview  │  │ Overlays   │  │ (ISO/Shutter/FPS/WB)    │ │
│  │          │  │ (zebra,    │  │                         │ │
│  │ SharedMem│  │  false clr,│  │ Settings Panel          │ │
│  │ + MJPEG  │  │  focus pk) │  │ (overlays, compression) │ │
│  └────┬─────┘  └────────────┘  └───────────┬─────────────┘ │
│       │                                     │               │
│       │  Shared Memory (zero-copy)    Redis │               │
└───────┼─────────────────────────────────────┼───────────────┘
        │                                     │
┌───────┴─────────────────────────────────────┴───────────────┐
│                    cinepi-raw (Backend)                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │libcamera │→ │DNG       │  │MJPEG     │  │Redis       │  │
│  │capture   │  │encoder   │  │streamer  │  │pub/sub     │  │
│  └──────────┘  └──────────┘  └──────────┘  └────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Configuration

### Sensor Tuning

The `run-raw.sh` script accepts environment variables to customize the sensor:

```bash
# Use a different tuning file
TUNING_FILE=~/kurokesu-cinepi/tuning/imx477.json ./scripts/run-raw.sh

# Change sensor mode
SENSOR_MODE=1920:1080:10:U ./scripts/run-raw.sh

# Change preview resolution
LORES_WIDTH=1280 LORES_HEIGHT=720 ./scripts/run-raw.sh
```

### Redis Keys

The backend and GUI communicate via Redis. Key parameters:

| Key | Description | Example |
|-----|-------------|---------|
| `iso` | Sensor ISO | `800` |
| `shutter_a` | Shutter angle (degrees) | `180` |
| `fps` | Frame rate | `24` |
| `awb` | White balance (Kelvin, 0=auto) | `5600` |
| `is_recording` | Recording state | `0` or `1` |
| `compress` | Compression (0=none, 1=lossy, 2=lossless) | `0` |
| `cg_rb` | Color gains (red,blue) | `1.5,1.2` |
| `width`, `height` | Capture resolution | `2784`, `1828` |

## Manual Build

If you prefer to build components individually:

### cinepi-raw

```bash
cd cinepi-raw
meson setup build -Denable_libav=enabled -Denable_drm=enabled -Denable_egl=enabled --buildtype=release
meson compile -C build
sudo meson install -C build
```

### cinepi-qt

```bash
cd cinepi-qt
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

## Troubleshooting

### No camera preview

1. Check that cinepi-raw is running: `systemctl status cinepi-raw`
2. Verify camera detection: `rpicam-hello --list-cameras`
3. Check Redis is running: `redis-cli ping` (should return `PONG`)
4. Check logs: `journalctl -u cinepi-raw -n 50`

### GUI doesn't start

1. Check Wayland is running: `echo $WAYLAND_DISPLAY`
2. Try running manually: `./scripts/run-qt-gui.sh`
3. Check logs: `journalctl -u cinepi-qt -n 50`

### NVMe not detected

1. Verify PCIe is enabled in `/boot/firmware/config.txt`:
   ```ini
   dtparam=pciex1
   dtparam=pciex1_gen=3
   ```
2. Check NVMe is visible: `lsblk`
3. Format if needed: `sudo mkfs.exfat /dev/nvme0n1p1`

## Credits

- [CinePI](https://github.com/cinepi/cinepi-sdk) - Original cinema camera platform
- [ALTCINECAM](https://github.com/ALTCINECAM) - Alternative CinePI distribution
- [rpicam-apps](https://github.com/raspberrypi/rpicam-apps) - Raspberry Pi camera framework
- [Kurokesu](https://www.kurokesu.com) - CSI-2 camera modules and sensor support

## License

This project incorporates components with different licenses:
- cinepi-raw: BSD-2-Clause (based on rpicam-apps)
- cinepi-qt: MIT
- Sensor drivers: GPL-2.0 (kernel modules)
