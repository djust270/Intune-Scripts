# Proactive remediation detection script to determine if user is a local Administrator
$group =[ADSI]"WinNT://$($env:COMPUTERNAME)/Administrators"
$admins = @($group.Invoke("Members")) | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
$user = ((gcim win32_computersystem).username -split '\\')[1]
if ($admins -like $user)
{
    Write-Host "User is Admin"
    exit 1
}
else
{
    Write-Host "User is not Admin"
    exit 0
}