#!/bin/bash
#######################################
# Deploy a ovpn file for aws client vpn
# Arguments:
#   $1: OpenVPN file
#       e.g.) file://tmp/aws-vpn.ovpn
#   $2: Profile name displayed in AWS VPN Client
#       e.g.) aws-vpn
#   $3: CvpnEndpointId
#       e.g.) cvpn-endpoint-XXXXXXXXXXXXXXXXX
#   $4: CvpnEndpointRegion
#       e.g.) ap-northeast-1
#   $5: CompatibilityVersion
#       1 : Use mutual authentication
#         : Use Active Directory authentication
#       2 : Use Federated authentication
#   $6: FederatedAuthType
#       0 : Use mutual authentication
#         : Use Active Directory authentication
#       1 : Use Federated authentication
# If you do not know the Arguments, please check the following file path.
# {LOGGED_IN_USER}/.config/AWSVPNClient/ConnectionProfiles
#######################################

# TODO(enpipi) : Checking the behavior when using Active Directory authentication. (enhancement #1)
VERSION='0.1.0'
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# Output info log with timestamp
print_info_log(){
  local timestamp
  timestamp=$(date +%F\ %T)

  echo "$timestamp [INFO] $1"
}

# Output error log with timestamp
print_error_log(){
  local timestamp
  timestamp=$(date +%F\ %T)

  echo "$timestamp [ERROR] $1"
}


# Check for the existence of aws client vpn
if [[ ! -e "/Applications/AWS VPN Client/AWS VPN Client.app" ]];then
  print_error_log "It seems that the AWS VPN Clinet is not installed. Please install it and try again."
  exit 1
fi


if [[ "${1}" = "/" ]];then
	# Jamf uses sends '/' as the first argument
  print_info_log "Shifting arguments for Jamf."
  shift 3
fi

if [[ "${1:l}" = "version" ]];then
  echo "${VERSION}"
  exit 0
fi

if [[ ! "${1}" ]];then
  print_error_log "You need to set ovpn file location."
  exit 1
fi
OVPN_FILE_PATH="${1}"


# TODO(enpipi): Check .ovpn file
# print_error_log "File format is not ovpn. You need to set .ovpn file."


if [[ ! "${2}" ]];then
  print_error_log "You need to set aws vpn client profile name."
  exit 1
fi
PRFILE_NAME="${2}"

# TODO(enpipi): Only alphanumeric characters and "　,　-, _, (,)" can be used for display name.
# print_error_log "Only alphanumeric characters and "　,　-, _, (,)" can be used for display name."


if [[ ! "${3}" ]];then
  print_error_log "You need to set CvpnEndpointId."
  exit 1
fi
C_VPN_ENDPOINT_ID="${3}"


if [[ ! "${4}" ]];then
  print_error_log "You need to set CvpnEndpointRegion."
  exit 1
fi
C_VPN_ENDPOINT_REGION="${4}"

if [[ ! "${5}" ]];then
  print_error_log "You need to set CompatibilityVersion."
  exit 1
fi
COMATIBILITY_VERSION="${5}"

if [[ ! "${6}" ]];then
  print_error_log "You need to set FederatedAuthType."
  exit 1
fi
FEDERATED_AUTH_TYPE="${6}"


print_info_log "Start aws vpn client profile deplyment..."

# Launch and exit the application to generate the initial config file.
# If you don't do this, the application won't launch properly even if you place the ovpn file in the config.
# TODO: Find a way to get the difference when adding and not launch the application.
open -j -a "/Applications/AWS VPN Client/AWS VPN Client.app"
osascript -e 'quit app "AWS VPN Client.app"'



# Find the loggedInUser
LOGGED_IN_USER=$(stat -f %Su /dev/console)

# Set the file path to the ConnectionProfiles file with the loggedIn user
CONNECTION_PROFILES="/Users/$LOGGED_IN_USER/.config/AWSVPNClient/ConnectionProfiles"
OPEN_VPN_CONFIGS_DIRECTORY="/Users/$LOGGED_IN_USER/.config/AWSVPNClient/OpenVpnConfigs"

# Delete auth-federate in OVPN_FILE_PATH
print_info_log "delete auth-federate in ${OVPN_FILE_PATH}"
sed -i -e '/auth-federate/d' "${OVPN_FILE_PATH}"

# Copy and rename ovpn file
print_info_log "copy and rename ovpn file from ${OVPN_FILE_PATH} to ${OPEN_VPN_CONFIGS_DIRECTORY}/${PRFILE_NAME}"
cp "${OVPN_FILE_PATH}" "${OPEN_VPN_CONFIGS_DIRECTORY}/${PRFILE_NAME}"

# Get backup of ConnectionProfiles
print_info_log "Get backup of ${CONNECTION_PROFILES}"
CONNECTION_PROFILES_BACKUP="/Users/$LOGGED_IN_USER/.config/AWSVPNClient/_ConnectionProfiles"
cp "$CONNECTION_PROFILES" "$CONNECTION_PROFILES_BACKUP"


# Make the file
# TODO(enpipi): Add the profile if it already exists, or overwrite it if it doesn't.
# We need to realize this TODO with awk and sed.
# This is because we have to assume that the terminal does not have JQ installed on it.
cat <<EOF > "$CONNECTION_PROFILES"
{
  "Version":"1",
  "LastSelectedProfileIndex":0,
  "ConnectionProfiles":[
    {
      "ProfileName":"${PRFILE_NAME}",
      "OvpnConfigFilePath":"/Users/$LOGGED_IN_USER/.config/AWSVPNClient/OpenVpnConfigs/${PRFILE_NAME}",
      "CvpnEndpointId":"${C_VPN_ENDPOINT_ID}",
      "CvpnEndpointRegion":"${C_VPN_ENDPOINT_REGION}",
      "CompatibilityVersion":"${COMATIBILITY_VERSION}",
      "FederatedAuthType":${FEDERATED_AUTH_TYPE}
    }
  ]
}
EOF

print_info_log "End aws vpn client profile deplyment..."


# Fix permissions
chown "$LOGGED_IN_USER" "$CONNECTION_PROFILES"
