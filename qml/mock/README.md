# QML Mock Preview

Open `MockMain.qml` in Qt Design Studio or run with `qml` to preview the UI without the camera backend.

```bash
# Run standalone preview (requires Qt6)
qml MockMain.qml
```

The mock provides:
- `camera` — QtObject with all CameraController properties and stub functions
- `config` — QtObject with all ConfigManager properties
- A grey rectangle in place of the DmaBufPreview camera feed

Edit the mock property values to test different UI states (recording, disconnected, high ISO, etc.).

Note: ShaderOverlays are excluded from the mock since they require compiled `.qsb` shader files.
