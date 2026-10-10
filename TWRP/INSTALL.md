# Install TWRP — Galaxy S22 SM-S901B

**Requirements:** Unlocked bootloader. Back up important data before flashing.

## Flash

1. Boot into **Download Mode** and connect the phone to your computer.
2. Flash `S901B_twrp_vbmeta_only.tar`:
   - **Windows (Odin):** Select the TAR in **AP**, leave other slots empty, disable **Auto Reboot**, and click **Start**.
   - **Linux (Odin4):**
     ```bash
     odin4 -a S901B_twrp_vbmeta_only.tar -d "<detected-device>"
     ```
3. After flashing, hold **Volume Down + Side/Power** until the screen turns black, then immediately switch to **Volume Up + Side/Power**. Keep the USB cable connected.
4. At the Samsung logo, release **Side/Power** but keep holding **Volume Up** until TWRP opens.
