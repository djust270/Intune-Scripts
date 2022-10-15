Connect-MGGraph -Scope "Directory.ReadWrite.All"
$GroupParams = @{
    DisplayName = "Intune Users"
    Description ="Dynamic Group for Intune Users"
    GroupTypes = "DynamicMembership"
    Membershiprule = '(user.assignedPlans -any (assignedPlan.servicePlanId -eq "c1ec4a95-1f05-45b3-a911-aa3fa01094f5" -and assignedPlan.capabilityStatus -eq "Enabled"))'
    MailEnabled = $False
    MailNickName = 'AutopilotDevices'
    SecurityEnabled = $True
    MembershipRuleProcessingState = "On"
        }
New-MGGroup -BodyParameter $GroupParams
Disconnect-MGGraph