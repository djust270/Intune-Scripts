Install-Module azureadpreview -AllowClobber -Force -Confirm:$false
Import-Module AzureADPreview
Connect-AzureAD

#Create Dynamic Device Group for Autopilot

$AutoPilotGroup = @{
    DisplayName = "Autopilot Devices"
    Description ="Dynamic Group for Autpilot Devices"
    GroupTypes = "DynamicMembership"
    Membershiprule = '(device.devicePhysicalIDs -any _ -contains "[ZTDId]")'
    MailEnabled = $False
    MailNickName = 'AutopilotDevices'
    SecurityEnabled = $True
    MembershipRuleProcessingState = "On"
        }
if ((Get-AzureADMSGroup | Where Displayname -like "Autopilot Devices") -eq $Null){

New-AzureADMSGroup @AutopilotGroup
}
Disconnect-AzureAD