#!/bin/zsh

############################################################
# macOS Application Inventory Script
# Collects installed applications and versions
# Modular design for reuse in inventory/compliance tooling
############################################################

set -euo pipefail

############################################################
# CONFIGURATION
############################################################

# Default search paths for applications
APP_PATHS=(
    "/Applications"
    "/System/Applications"
    "/Applications/Utilities"
    "$HOME/Applications"
)

# Output file
CSV_OUTPUT="/tmp/macos_application_inventory.csv"

# Array to hold results
typeset -a APP_DATA


############################################################
# FUNCTION: get_app_version
# Extract version from Info.plist
############################################################
get_app_version() {

    local app_path="$1"

    local version

    version=$(defaults read "$app_path/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)

    if [[ -z "$version" ]]; then
        version=$(defaults read "$app_path/Contents/Info.plist" CFBundleVersion 2>/dev/null)
    fi

    echo "${version:-Unknown}"
}


############################################################
# FUNCTION: get_bundle_id
############################################################
get_bundle_id() {

    local app_path="$1"

    local bundle

    bundle=$(defaults read "$app_path/Contents/Info.plist" CFBundleIdentifier 2>/dev/null)

    echo "${bundle:-Unknown}"
}


############################################################
# FUNCTION: collect_apps_from_path
############################################################
collect_apps_from_path() {

    local search_path="$1"

    [[ ! -d "$search_path" ]] && return

    while IFS= read -r app; do

        local name
        local version
        local bundle

        name=$(basename "$app" .app)
        version=$(get_app_version "$app")
        bundle=$(get_bundle_id "$app")

        APP_DATA+=("${name}|${version}|${bundle}|${app}")

    done < <(find "$search_path" -maxdepth 2 -type d -name "*.app" 2>/dev/null)

}


############################################################
# FUNCTION: collect_all_apps
############################################################
collect_all_apps() {

    for path in "${APP_PATHS[@]}"; do
        collect_apps_from_path "$path"
    done

}


############################################################
# FUNCTION: export_csv
############################################################
export_csv() {

    local file="$1"

    echo "Name,Version,BundleID,Path" > "$file"

    for entry in "${APP_DATA[@]}"; do

        IFS="|" read -r name version bundle path <<< "$entry"

        echo "\"$name\",\"$version\",\"$bundle\",\"$path\"" >> "$file"

    done

}


############################################################
# FUNCTION: print_table
############################################################
print_table() {

    printf "%-40s %-15s %-35s %s\n" "Name" "Version" "BundleID" "Path"
    printf "%s\n" "------------------------------------------------------------------------------------------------------------"

    for entry in "${APP_DATA[@]}"; do

        IFS="|" read -r name version bundle path <<< "$entry"

        printf "%-40s %-15s %-35s %s\n" "$name" "$version" "$bundle" "$path"

    done

}


############################################################
# MAIN
############################################################

main() {

    echo "Collecting installed applications..."

    collect_all_apps

    echo "Found ${#APP_DATA[@]} applications"

    print_table

    export_csv "$CSV_OUTPUT"

    echo ""
    echo "CSV exported to:"
    echo "$CSV_OUTPUT"

}

main