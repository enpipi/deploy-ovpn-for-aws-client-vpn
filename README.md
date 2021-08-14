# deploy-ovpn-for-aws-client-vpn
This is a script to distribute AWS VPN Client profiles using Jamf.

## Prerequisite
- AWS VPN Client must be pre-installed.

## Notes
- It will be overwritten, not added. It is not possible to add or distribute multiple profiles to an existing environment.
- I have not been able to test with "Active Directory authentication".
- If you do not know the Arguments, please check the following file path.
`# {LOGGED_IN_USER}/.config/AWSVPNClient/ConnectionProfiles`

## Arguments
The following parameters can be specified
- $1: OpenVPN File
    - e.g.) file://tmp/aws-vpn.ovpn
- $2: Profile name displayed in AWS VPN Client
    - e.g.) aws-vpn
- $3: CvpnEndpointId
    - e.g.) cvpn-endpoint-XXXXXXXXXXXXXXXXX
- $4: CvpnEndpointRegion
    - e.g.) us-west-1, ap-northeast-1
- $5: CompatibilityVersion
    - 1 : Use mutual authentication
    - 2 : Use Federated authentication
    - ? : Use Active Directory authentication
- $6: FederatedAuthType
    - 0 : Use mutual authentication
    - 1 : Use Federated authentication
    - ? : Use Active Directory authentication
