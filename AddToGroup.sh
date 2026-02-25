#!/bin/zsh

########################################################################
# Add User to Groups (macOS - Zsh)
# Designed for Jamf Pro deployment
#
# Parameter 4: Username
# Parameter 5: Comma-separated group list
#
# Example:
# Param 4 = john
# Param 5 = staff,_developer,docker
########################################################################

print "----- Add User To Groups (Zsh) -----"

USERNAME="$4"
GROUP_LIST="$5"

# Validate parameters
if [[ -z "$USERNAME" || -z "$GROUP_LIST" ]]; then
    print "ERROR: Missing parameters."
    print "Parameter 4 = Username"
    print "Parameter 5 = Comma-separated groups"
    exit 1
fi

# Validate user exists
if ! id "$USERNAME" &>/dev/null; then
    print "ERROR: User '$USERNAME' does not exist."
    exit 1
fi

# Convert comma-separated list to array
IFS=',' read -A GROUPS <<< "$GROUP_LIST"

for GROUP in "${GROUPS[@]}"; do

    # Trim whitespace
    GROUP="$(echo "$GROUP" | xargs)"

    # Check if group exists
    if ! dscl . -read "/Groups/$GROUP" &>/dev/null; then
        print "Group '$GROUP' does not exist. Creating..."
        if ! dseditgroup -o create "$GROUP"; then
            print "ERROR: Failed to create group '$GROUP'"
            continue
        fi
    fi

    # Check if user already a member
    if dseditgroup -o checkmember -m "$USERNAME" "$GROUP" 2>/dev/null | grep -q "yes"; then
        print "User '$USERNAME' already in '$GROUP'"
        continue
    fi

    # Add user to group
    print "Adding '$USERNAME' to '$GROUP'..."
    if dseditgroup -o edit -a "$USERNAME" -t user "$GROUP"; then
        print "SUCCESS: Added '$USERNAME' to '$GROUP'"
    else
        print "ERROR: Failed to add '$USERNAME' to '$GROUP'"
    fi

done

print "Script completed."
exit 0
