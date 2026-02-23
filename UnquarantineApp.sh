#!/bin/zsh
#Remove application from Apple's quarantine.

#Timestamp command to be used in the output.
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")


#theCommand='display dialog "blah blah blah" with title "Blah Title" with icon posix file "/Applications/Self Service.app/Contents/Resources/AppIcon.icns"'

#/usr/bin/osascript -e "$theCommand"

POPUP='display dialog "Please enter the file path with the Application" with title "File Path" with icon posix file "/Library/User Pictures/Animals/Eagle.heic"'

FILEPATH='display dialog "Please enter the file path with the Application" default answer "/Applications/" buttons {"Cancel","OK"} default button {"OK"}'

theButton=$( echo "$FILEPATH" | /usr/bin/awk -F "button returned:|," '{print $2}' )
theText=$( echo "$FILEPATH" | /usr/bin/awk -F "text returned:" '{print $2}' )

#Function to unquarantine with an Interactive or CLI mode.
function unquarantine {
    MODE=$1
    APP=$2
    #Check to see if to run script in CLI only or Interactive mode
    if [[ $MODE == 'i' ]]
    then
        echo "${TIMESTAMP}: Interactive mode is selected."
        #Get the file path of the application.
        /usr/bin/osascript -e "$FILEPATH"
        echo $theButton
        echo $theText
        exit 1
    else
        echo "${TIMESTAMP}: This script will run in CLI mode."
        echo "${TIMESTAMP}: Checking to see if the application is in the Applications folder."
        if [[ $APP == *.app ]]
        then
            echo "${TIMESTAMP}: Supplied value has .app attached"
        else
            echo "${TIMESTAMP}: Supplied value does not have .app attached"
            echo "${TIMESTAMP}: Adding .app to: $APP"
            APP="$APP".app
            echo "${TIMESTAMP}: The new value is: $APP"
        fi

        if [[ "$APP" == */* ]]
        then
            echo "${TIMESTAMP}: The file path for the provided application was supplied"
            echo "${TIMESTAMP}: About to unquarantine " $APP | sed 's:.*/::'
            #xattr -d com.apple.quarantine $APP
            echo "${TIMESTAMP}: Unquarantined " $APP | sed 's:.*/::'

        else
            echo "${TIMESTAMP}: The file path for the provided application was not supplied."
            echo "${TIMESTAMP}: Checking the Applications folder for the app."
            if [[ -d "/Applications/$APP" ]]
            then
                echo "${TIMESTAMP}: Found " $APP
                echo "${TIMESTAMP}: About to unquarantine " $APP
                #xattr -d com.apple.quarantine /Applications/$APP
                echo "${TIMESTAMP}: Unquarantined " $APP
            else
                echo "${TIMESTAMP}: Did not find $APP in the Appliations folder"
                echo "${TIMESTAMP}: Exiting script."
                exit 1
            fi
        fi
    fi
}

unquarantine $1 $2
exit 0
