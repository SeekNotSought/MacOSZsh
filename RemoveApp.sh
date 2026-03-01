#!/bin/zsh

############################################################
# macOS Application Removal Script
# Compatible with Jamf Pro
#
# Usage in Jamf:
# Parameter 4 = Application Name (Example: "Google Chrome.app")
#
# Example:
# sudo ./RemoveApp.zsh "Google Chrome.app"
############################################################

# Jamf passes script parameters like this:
APP_NAME="$4"

# If running locally (not via Jamf), allow manual argument
if [[ -z "$APP_NAME" && -n "$1" ]]; then
    APP_NAME="$1"
fi

if [[ -z "$APP_NAME" ]]; then
    echo "ERROR: No application name supplied."
    echo "In Jamf, set Parameter 4 to the full app name (e.g., 'Slack.app')"
    exit 1
fi

echo "Starting removal process for: $APP_NAME"

# Function: Quit app if running
quit_app() {
    local app="$1"
    local process_name="${app%.app}"

    if pgrep -x "$process_name" >/dev/null 2>&1; then
        echo "Application is running. Attempting graceful quit..."
        pkill -15 -x "$process_name"
        sleep 5

        if pgrep -x "$process_name" >/dev/null 2>&1; then
            echo "Force quitting application..."
            pkill -9 -x "$process_name"
        fi
    else
        echo "Application not currently running."
    fi
}

# Function: Remove app bundle
remove_app_bundle() {
    local app="$1"

    APP_PATHS=(
        "/Applications/$app"
        "/Applications/Utilities/$app"
        "/Users/*/Applications/$app"
    )

    for path in "${APP_PATHS[@]}"; do
        for expanded in $path; do
            if [[ -d "$expanded" ]]; then
                echo "Removing: $expanded"
                rm -rf "$expanded"
            fi
        done
    done
}

# Function: Remove support files
remove_support_files() {
    local app="$1"
    local app_base="${app%.app}"

    echo "Searching for related support files..."

    find /Library -iname "*$app_base*" -maxdepth 3 -exec rm -rf {} + 2>/dev/null
    find /Users -iname "*$app_base*" -maxdepth 4 -exec rm -rf {} + 2>/dev/null
}

# Execute removal steps
quit_app "$APP_NAME"
remove_app_bundle "$APP_NAME"
remove_support_files "$APP_NAME"

echo "Removal process completed for: $APP_NAME"
exit 0