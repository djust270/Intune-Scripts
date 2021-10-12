$group =[ADSI]"WinNT://$($env:COMPUTERNAME)/Administrators"
$admins = @($group.Invoke("Members")) | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
$user = ((gcim win32_computersystem).username -split '\\')[1]
Net Localgroup Administrators /delete (gcim win32_computersystem).username

$adminspost = @($group.Invoke("Members")) | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
if ($adminspost -like $user)
{
    Write-Host "User is Admin"
    exit 1
}
else
{
    Write-Host "User is not Admin"
    exit 0
}