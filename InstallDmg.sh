#!/bin/zsh

# ============================================================
# Jamf DMG Installer Script (zsh)
# Author: Your Name
# Description: Mounts DMG, installs .app or .pkg, cleans up
# ============================================================

# -------- Variables --------
DMG_NAME="$4"
JAMF_DOWNLOAD_DIR="/Library/Application Support/JAMF/Downloads"
DMG_PATH="${JAMF_DOWNLOAD_DIR}/${DMG_NAME}"
MOUNT_POINT="/Volumes/DMGInstall"
LOG_FILE="/var/log/jamf_dmg_install.log"

# -------- Logging Function --------
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# -------- Validation --------
if [[ -z "$DMG_NAME" ]]; then
    log "ERROR: No DMG name supplied in Parameter 4."
    exit 1
fi

if [[ ! -f "$DMG_PATH" ]]; then
    log "ERROR: DMG not found at $DMG_PATH"
    exit 1
fi

log "Starting installation of $DMG_NAME"

# -------- Mount DMG --------
log "Mounting DMG..."
hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_POINT" -nobrowse -quiet

if [[ $? -ne 0 ]]; then
    log "ERROR: Failed to mount DMG."
    exit 1
fi

# -------- Detect Installer Type --------
APP_PATH=$(find "$MOUNT_POINT" -maxdepth 2 -name "*.app" -type d | head -n 1)
PKG_PATH=$(find "$MOUNT_POINT" -maxdepth 2 -name "*.pkg" -type f | head -n 1)

if [[ -n "$APP_PATH" ]]; then
    log "Found application: $APP_PATH"
    log "Copying to /Applications..."
    cp -R "$APP_PATH" /Applications/

    if [[ $? -ne 0 ]]; then
        log "ERROR: Failed to copy application."
        hdiutil detach "$MOUNT_POINT" -quiet
        exit 1
    fi

elif [[ -n "$PKG_PATH" ]]; then
    log "Found package installer: $PKG_PATH"
    log "Installing package..."
    installer -pkg "$PKG_PATH" -target /

    if [[ $? -ne 0 ]]; then
        log "ERROR: Package installation failed."
        hdiutil detach "$MOUNT_POINT" -quiet
        exit 1
    fi

else
    log "ERROR: No .app or .pkg found inside DMG."
    hdiutil detach "$MOUNT_POINT" -quiet
    exit 1
fi

# -------- Cleanup --------
log "Unmounting DMG..."
hdiutil detach "$MOUNT_POINT" -quiet

log "Removing downloaded DMG..."
rm -f "$DMG_PATH"

log "Installation completed successfully."

exit 0