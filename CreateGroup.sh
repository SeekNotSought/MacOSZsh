#!/bin/zsh

# ---------------------------
# Configuration (Jamf-friendly)
# ---------------------------

GROUP_NAME="$4"
GROUP_GID="$5"               # Optional: leave empty for auto-assigned
ADD_USERS=("$6")   # Optional: add existing users to group

# ---------------------------
# Function: Check if group exists
# ---------------------------

if dscl . -read /Groups/"$GROUP_NAME" &>/dev/null; then
    echo "Group '$GROUP_NAME' already exists. Exiting."
    exit 0
fi

echo "Creating group '$GROUP_NAME'..."

# ---------------------------
# Create the group
# ---------------------------

if [[ -n "$GROUP_GID" ]]; then
    dscl . -create /Groups/"$GROUP_NAME"
    dscl . -create /Groups/"$GROUP_NAME" PrimaryGroupID "$GROUP_GID"
else
    dseditgroup -o create "$GROUP_NAME"
fi

# Verify creation
if ! dscl . -read /Groups/"$GROUP_NAME" &>/dev/null; then
    echo "Failed to create group."
    exit 1
fi

echo "Group '$GROUP_NAME' created successfully."

# ---------------------------
# Add users to group
# ---------------------------

for USER in "${ADD_USERS[@]}"; do
    if id "$USER" &>/dev/null; then
        echo "Adding $USER to $GROUP_NAME..."
        dseditgroup -o edit -a "$USER" -t user "$GROUP_NAME"
    else
        echo "User $USER does not exist. Skipping."
    fi
done

echo "Script complete."
exit 0