#!/bin/zsh

########################################################################
# Create Local User and Add to Groups
# Optimized for Jamf Pro deployment
########################################################################

# Jamf Parameters
USERNAME="$4"
FULLNAME="$5"
PASSWORD="$6"
GROUPLIST="$7"
USER_UID="$8"

LOG_PREFIX="[User Provisioning]"

echo "$LOG_PREFIX Starting script..."

########################################################################
# Validation
########################################################################

if [[ -z "$USERNAME" || -z "$FULLNAME" || -z "$PASSWORD" ]]; then
    echo "$LOG_PREFIX ERROR: Username, Full Name, and Password are required."
    exit 1
fi

########################################################################
# Generate UID if not provided
########################################################################

if [[ -z "$USER_UID" ]]; then
    USER_UID=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -n | tail -1)
    USER_UID=$((USER_UID + 1))
fi

########################################################################
# Create User (if not exists)
########################################################################

if id "$USERNAME" &>/dev/null; then
    echo "$LOG_PREFIX User $USERNAME already exists. Skipping creation."
else
    echo "$LOG_PREFIX Creating user $USERNAME..."

    dscl . -create /Users/"$USERNAME"
    dscl . -create /Users/"$USERNAME" UserShell /bin/zsh
    dscl . -create /Users/"$USERNAME" RealName "$FULLNAME"
    dscl . -create /Users/"$USERNAME" UniqueID "$USER_UID"
    dscl . -create /Users/"$USERNAME" PrimaryGroupID 20
    dscl . -create /Users/"$USERNAME" NFSHomeDirectory /Users/"$USERNAME"

    dscl . -passwd /Users/"$USERNAME" "$PASSWORD"
    createhomedir -c -u "$USERNAME" > /dev/null

    echo "$LOG_PREFIX User $USERNAME created successfully."
fi

########################################################################
# Add User to Groups
########################################################################

if [[ -n "$GROUPLIST" ]]; then
    IFS=',' read -A GROUPS <<< "$GROUPLIST"

    for GROUP in "${GROUPS[@]}"; do
        GROUP=$(echo "$GROUP" | xargs)  # trim whitespace

        if dscl . -read /Groups/"$GROUP" &>/dev/null; then
            if dseditgroup -o checkmember -m "$USERNAME" "$GROUP" | grep -q "yes"; then
                echo "$LOG_PREFIX $USERNAME already in $GROUP."
            else
                echo "$LOG_PREFIX Adding $USERNAME to $GROUP..."
                dseditgroup -o edit -a "$USERNAME" -t user "$GROUP"
            fi
        else
            echo "$LOG_PREFIX WARNING: Group $GROUP does not exist. Skipping."
        fi
    done
fi

########################################################################
# Done
########################################################################

echo "$LOG_PREFIX Completed successfully."
exit 0