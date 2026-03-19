--- START OF FILE README.md ---

# termux-linux-setup (VNC Edition)

A unified and enhanced script to easily set up native Linux desktop environments (XFCE4, LXQt, MATE, KDE) on Android via Termux, now primarily using a **VNC Server** for remote access. This script includes smart GPU acceleration (Turnip/Zink), audio, Windows app support (Box64/Wine), a comprehensive set of default tools, and robust pre-installation checks.

## Features

*   **VNC Server Integration:** Access your Linux desktop remotely using any VNC client (e.g., VNC Viewer) on your Android device or another device on your network.
*   **Choice of Desktop Environment:** Select from XFCE4, LXQt, MATE, or KDE Plasma to best suit your device's capabilities and preferences.
*   **Smart GPU Acceleration:** Automatically detects Adreno GPUs (Qualcomm Snapdragon) for Turnip driver setup, or uses Zink for other GPUs, enhancing graphical performance.
*   **Full Audio Support:** PulseAudio is configured for sound output in your Linux environment.
*   **Windows App Compatibility:** Includes Wine and Box64/Hangover to run Windows applications.
*   **Productivity & Development Tools:** Pre-installs Firefox, VLC Media Player, Git, Curl, Wget, and Python (with Flask demo).
*   **System Information Tool:** `neofetch` is included to display system details beautifully.
*   **Robust Pre-installation Checks:** Verifies Termux storage permissions, available disk space, and internet connectivity before starting the installation.
*   **User-Friendly Interface:** Features a clear progress bar, colored output, and interactive prompts for a smooth setup experience.

## Prerequisites

Before running this script, you must ensure you have the correct versions of the required applications on your Android device.

1.  **Termux Base App**: Do not download Termux from the Google Play Store, as that version is broken and no longer receives updates. You must download the official, updated version from F-Droid:
    *   [Download Termux (F-Droid)](https://f-droid.org/en/packages/com.termux/)

2.  **VNC Client App**: Since this setup uses a VNC server, you will need a VNC client application on your Android device (or any other device you wish to connect from) to view and interact with the Linux desktop. Popular choices include:
    *   **VNC Viewer** (Recommended for Android)
    *   **RealVNC Viewer**
    *   **aRDP Free RDP Client** (supports VNC as well)

    Download any suitable VNC client from your device's app store (e.g., Google Play Store, F-Droid).

## How to Install

Once you have the **Termux app** installed and your preferred **VNC Client app** ready on your phone, open the primary **Termux** app and follow these steps:

1.  **Grant Storage Permission:** It's crucial that Termux has access to your device's storage. Run the following command and grant the necessary permission when prompted:
    ```bash
    termux-setup-storage
    ```
    *(The script will check this again, but it's good practice to do it beforehand.)*

2.  **Download and Run the Setup Script:** Paste the following commands into Termux to automatically download and execute the setup script:
    ```bash
    curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/termux-linux-setup.sh && chmod +x termux-linux-setup.sh && ./termux-linux-setup.sh
    ```
    *   **Note:** Replace `https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/termux-linux-setup.sh` with the actual URL where you host this script, or adapt the command if you save it locally.

    The script will guide you through:
    *   Device detection and GPU information.
    *   Choosing your desired Desktop Environment (XFCE4, LXQt, MATE, KDE Plasma).
    *   Setting a **VNC password** (6-8 characters long).

## How to Use

After the installation is complete:

1.  **Start the Linux Desktop (VNC Server):**
    Open the Termux app and run:
    ```bash
    ./start-linux.sh
    ```
    This will start the VNC server and the chosen desktop environment.

2.  **Connect with a VNC Client:**
    *   Open your **VNC client app** on your Android device.
    *   Create a new connection.
    *   For the **IP Address/Hostname**, use `127.0.0.1`.
    *   For the **Port**, use `5901`.
    *   When prompted, enter the **VNC password** you set during the installation.
    *   You should now see your Linux desktop!

    *   **Connecting from another device (e.g., PC, tablet) on the same Wi-Fi network:**
        You'll need your Android device's local IP address (e.g., `192.168.1.100`). You can find this in your Android device's Wi-Fi settings or by running `ifconfig` in Termux. Then, connect to that IP address on port `5901` using your VNC client on the other device.

3.  **Stop the Linux Desktop (VNC Server):**
    To stop the VNC server and free up resources, open the Termux app and run:
    ```bash
    ./stop-linux.sh
    ```

## Post-Installation Notes

*   **GPU Acceleration:** While GPU drivers are installed, the actual hardware acceleration experience within the VNC client may vary. VNC primarily streams screen images, so it might not fully leverage your device's GPU for rendering the desktop itself, but applications *within* the desktop environment will benefit from the installed GPU drivers.
*   **Python Flask Demo:** A simple Python Flask web server demo is located in `~/demo_python`. You can run it with `python ~/demo_python/app.py` and access it from your Android browser at `http://127.0.0.1:5000`.
*   **Wine/Box64:** Windows applications will run, but performance will depend heavily on the complexity of the application and your device's CPU.
*   **Desktop Shortcuts:** Look for `Firefox`, `VLC Media Player`, `Wine Config`, `Neofetch`, and `Terminal` shortcuts on your new Linux desktop.

Enjoy your Linux desktop experience on Android!