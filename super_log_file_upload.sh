#!/bin/bash

# Woz | 3/14/23
## JSS Information ##
jssURL=""
apiID=""
apiPassword=''

## Global Variables ##
machineSerial=$(system_profiler SPHardwareDataType | grep Serial |  awk '{print $NF}' )
#currentUser=$(who | awk '/console/{print $1}')
bearerToken=""
jamfProID=""

## Functions/Token Handling ##
getBearerToken() {
response=$(curl -s -u "${apiID}:${apiPassword}" "$jssURL/api/v1/auth/token" -X POST)
bearerToken=$(echo "$response" | plutil -extract token raw -)
}

invalidateToken() {
responseCode=$(curl -w "%{http_code}" -H "Authorization: Bearer ${bearerToken}" $jssURL/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
if [[ ${responseCode} == 204 ]]; then
echo "Token successfully invalidated"
elif [[ ${responseCode} == 401 ]]
then
echo "Token already invalid"
else
echo "An unknown error occurred invalidating the token"
fi
}

## Log File Locations ##
superFolder="/Library/Management/super"
superLog="/Library/Management/super/super.log"
asuLog="/Library/Management/super/asu.log"
asuListLog="/Library/Management/super/asuList.log"
installerLog="/Library/Management/super/installer.log"
#mdmCommands="/Library/Management/super/mdmCommands.log"
current_time=$(date "+%m-%d-%Y-%H-%M")
new_fileName="super-logs_$current_time"
# Check if SUPER folder is not empty and then zip the files together
if [ -z "$(ls -A $superFolder)" ]; then
echo "SUPER folder does NOT exist. Exiting..."
exit 0
else
zip -j "/private/tmp/$new_fileName.zip" "$superLog" "$asuLog" "$asuListLog" "$installerLog"
fi

## Main Body Log ##
getBearerToken
jamfProID=$(curl -H "accept: application/xml" -H "Authorization: Bearer ${bearerToken}" -X GET "${jssURL}/JSSResource/computers/serialnumber/${machineSerial}/subset/general" | awk -F '<id>' '{print $2}' | awk -F '<' '{print $1}' )
curl -X POST "${jssURL}/api/v1/computers-inventory/${jamfProID}/attachments" -H "Authorization: Bearer ${bearerToken}" -F file=@/private/tmp/$new_fileName.zip
     
## Cleanup ##
rm "/private/tmp/$new_fileName.zip"
echo "Super log zip file removed"
invalidateToken
exit 0
