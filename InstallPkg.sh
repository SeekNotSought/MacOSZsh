#!/bin/zsh
####################################################################################################
# Script: InstallPkg.sh
# Description: Installs an application via pkg file with Jamf Pro compatibility
# Author: SeekNotSought
# Date: 02/28/2026
####################################################################################################

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Error handling function
handle_error() {
    log_message "ERROR: $1"
    echo "<result>Installation Failed: $1</result>"
    exit 1
}

# Set up logging
LOG_FILE="/var/log/$(basename $0 .sh)_install.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

log_message "=== Starting installation script v${VERSION} ==="

# Check if running as root (required for installation)
if [[ $EUID -ne 0 ]]; then
    handle_error "This script must be run as root"
fi

# Define variables - MODIFY THESE FOR YOUR APPLICATION
####################################################################################################
PKG_NAME="YourApp.pkg"                    # Name of the pkg file
APP_NAME="YourApp.app"                     # Name of the application (for verification)
PKG_PATH="/path/to/your/${PKG_NAME}"       # Path to the pkg file (local or mounted)
INSTALL_LOCATION="/Applications"            # Installation location (usually /Applications)
RECEIPT_NAME="com.yourcompany.yourapp"      # Package receipt name for verification
####################################################################################################

# Alternative: Get pkg from Jamf Pro distribution point
# PKG_PATH="/Library/Application Support/JAMF/Waiting Room/${PKG_NAME}"

# Verify pkg exists
if [[ ! -f "${PKG_PATH}" ]]; then
    handle_error "Package file not found at: ${PKG_PATH}"
fi

log_message "Package found: ${PKG_PATH}"

# Check if application is already installed and running
if [[ -d "/Applications/${APP_NAME}" ]]; then
    log_message "Application already installed, checking if running..."
    
    # Check if app is running and prompt to close (optional)
    RUNNING_PROCESS=$(ps aux | grep -i "${APP_NAME%.*}" | grep -v grep)
    if [[ -n "${RUNNING_PROCESS}" ]]; then
        log_message "WARNING: Application appears to be running"
        # Uncomment the following line if you want to force quit the application
        # killall "${APP_NAME%.*}" 2>/dev/null || true
    fi
fi

# Install the package
log_message "Installing package: ${PKG_NAME}"

# Option 1: Standard installer with target volume
/usr/sbin/installer -pkg "${PKG_PATH}" -target / >> "${LOG_FILE}" 2>&1
INSTALL_RESULT=$?

# Option 2: If you need to specify a particular volume or custom location
# /usr/sbin/installer -pkg "${PKG_PATH}" -target "${INSTALL_LOCATION}" >> "${LOG_FILE}" 2>&1
# INSTALL_RESULT=$?

# Check installation result
if [[ ${INSTALL_RESULT} -eq 0 ]]; then
    log_message "Package installed successfully"
else
    handle_error "Package installation failed with exit code: ${INSTALL_RESULT}"
fi

# Verify installation
log_message "Verifying installation..."

# Method 1: Check by receipt
if pkgutil --pkgs | grep -q "${RECEIPT_NAME}"; then
    log_message "Package receipt verified: ${RECEIPT_NAME}"
else
    log_message "Warning: Package receipt not found: ${RECEIPT_NAME}"
fi

# Method 2: Check if app exists in Applications
if [[ -d "/Applications/${APP_NAME}" ]]; then
    log_message "Application found at: /Applications/${APP_NAME}"
    
    # Get app version if available
    if [[ -f "/Applications/${APP_NAME}/Contents/Info.plist" ]]; then
        APP_VERSION=$(defaults read "/Applications/${APP_NAME}/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)
        log_message "Application version: ${APP_VERSION}"
    fi
else
    log_message "Warning: Application not found at standard location"
fi

# Set proper permissions (if needed)
# chown -R root:wheel "/Applications/${APP_NAME}" 2>/dev/null
# chmod -R 755 "/Applications/${APP_NAME}" 2>/dev/null

# Clean up (optional - uncomment if you want to remove the pkg after installation)
# log_message "Cleaning up package file..."
# rm -f "${PKG_PATH}"

# Jamf Pro specific: Update inventory
log_message "Updating Jamf Pro inventory..."
/usr/local/bin/jamf recon >> "${LOG_FILE}" 2>&1

# Final success output for Jamf Pro
log_message "=== Installation completed successfully ==="
echo "<result>Installation Successful</result>"
exit 0