![CinePI Kurokesu Edition](docs/banner.png)

![Version](https://img.shields.io/badge/Version-0.2.0-green?style=flat-square)

***Open-source cinema camera platform for Raspberry Pi - Kurokesu edition of [CinePI](https://github.com/cinepi/cinepi-sdk).***

![Raspberry Pi](https://img.shields.io/badge/-RaspberryPi-C51A4A?style=for-the-badge&logo=Raspberry-Pi)
![Debian](https://img.shields.io/badge/Debian-D70A53?style=for-the-badge&logo=debian&logoColor=white)
![Qt](https://img.shields.io/badge/Qt-%2341CD52.svg?style=for-the-badge&logo=qt&logoColor=white)
![C++](https://img.shields.io/badge/c++-%2300599C.svg?style=for-the-badge&logo=c%2B%2B&logoColor=white)
![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

# Overview

A fork and evolution of CinePI. Built on the libcamera API directly. Camera capture, DNG encoding, and Qt Quick UI all run in a single process with DMA-BUF zero-copy preview.

- **Qt Quick UI** running in Cage Wayland kiosk
- **DMA-BUF viewfinder** - zero-copy camera preview via EGL/GLES
- **12-bit CinemaDNG RAW** recording to NVMe SSD
- **GPU shader overlays** - zebra, false color, focus peaking, grayscale
- **Composition guides** - rule of thirds, crosshair, cinematic aspect ratios
- **MJPEG streaming** for remote monitoring

# Supported hardware

```bash
git clone --recurse-submodules https://github.com/kurokesu/kurokesu-cinepi.git
cd kurokesu-cinepi
```

### 2. Run the installer

```bash
./install.sh
```

The installer will:
- Install all system dependencies (Qt6, Redis, librpicam-app-dev, build tools)
- Build cinepi-raw (camera backend)
- Build cinepi-qt (Qt Quick GUI)
- Install default configuration files
- Set up systemd services for automatic startup
- Configure NVMe storage mount
- Optionally install sensor-specific kernel drivers

### 3. Configure your sensor

Edit `/boot/firmware/config.txt`:

```ini
# Disable automatic camera detection
camera_auto_detect=0
```

Add the overlay for your camera under the `[all]` section:

```ini
[all]
# Enable your sensor (uncomment one):
dtoverlay=imx283
#dtoverlay=imx477
#dtoverlay=imx585
#dtoverlay=imx462,clock-frequency=37125000

# If using HyperPixel 4 Square display:
#dtoverlay=vc4-kms-dpi-hyperpixel4sq
```

> **Note:** Sensors default to the **cam1** port. To use cam0 instead, append `,cam0`:
> ```ini
> dtoverlay=imx283,cam0
> ```

> **Note:** The IMX283 driver is included in the mainline RPi kernel (6.12+).
> Older kernels may require the DKMS driver from `drivers/imx283-v4l2-driver/`.

Reboot after making changes.

### 4. Start the camera

```bash
# Services start automatically on boot, or start manually:
sudo systemctl start cinepi-raw
sudo systemctl start cinepi-qt
```

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                      cinepi-qt (GUI)                       │
│  ┌──────────┐  ┌────────────┐   ┌────────────────────────┐ │
│  │ Camera   │  │ Shader     │   │ Camera Controls        │ │
│  │ Preview  │  │ Overlays   │   │ (ISO/Shutter/FPS/WB)   │ │
│  │          │  │ (zebra,    │   │                        │ │
│  │ SharedMem│  │  false clr,│   │ Settings Panel         │ │
│  │ + MJPEG  │  │  focus pk) │   │ (overlays, compression)│ │
│  └────┬─────┘  └────────────┘   └──────────┬─────────────┘ │
│       │                                    │               │
│       │  Shared Memory (zero-copy)   Redis │               │
└───────┼────────────────────────────────────┼───────────────┘
        │                                    │
┌───────┴────────────────────────────────────┴───────────────┐
│                    cinepi-raw (Backend)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────┐   │
│  │libcamera │→ │DNG       │  │MJPEG     │  │Redis      │   │
│  │capture   │  │encoder   │  │streamer  │  │pub/sub    │   │
│  └──────────┘  └──────────┘  └──────────┘  └───────────┘   │
│                                                            │
│  Links against system librpicam-app-dev (rpicam-apps)      │
└────────────────────────────────────────────────────────────┘
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
meson setup build --buildtype=release
ninja -C build
```

Requires `librpicam-app-dev` and dependencies (see `install.sh`).

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
