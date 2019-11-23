#If you are enforcing One Drive Known File Move, redirecting the Desktop, its possible some shortcuts may be duplicated 
#between the time the computer enrolls in intune and one drive redirects the desktop. This script will create a
#scheduled task to clear up and remove duplicated shortcuts if they exist at logon. 
#Just add in the shortcut name and your companies One Drive path. 

$dupe = '$UserSID = (New-Object -ComObject Microsoft.DiskQuota).TranslateLogonNameToSID((Get-WmiObject -Class Win32_ComputerSystem).Username)
$Path = "HKLM\SOFTWARE\Microsoft\WIndows NT\CurrentVersion\Profilelist\$UserSID"
$UserPath = Get-ItemProperty "Registry::$path" -name "ProfileImagePath" | select -ExpandProperty ProfileImagePath


$duplicateshortcuts = "shortcut1.lnk","shortcut2.lnk","shortcut3.lnk" | foreach {test-path "$UserPath\OneDrive - YourCompany\Desktop\$_."}
if ($duplicateshortcuts -eq $true)
{
$OldShortcuts = @("$UserPath\OneDrive - YourCompany\Desktop\shortcut1.lnk","$UserPath\OneDrive - YourCompany\Desktop\shortcut1.lnk.lnk","$UserPath\OneDrive - YourCompany\Desktop\shortcut3.lnk","$UserPath\OneDrive - YourCompany\Desktop\Microsoft Edge - Copy.lnk")
Get-ChildItem $OldShortcuts | Remove-Item
}'

new-item c:\automation -ItemType directory -force
set-content c:\automation\removedupshortcut.ps1 $dupe

if( -Not (Get-ScheduledTask -TaskName "Remove Duplicate Shortcuts" -ErrorAction SilentlyContinue -OutVariable task) )
    {
        $Params = @{
        Action = (New-ScheduledTaskAction -Execute 'powershell' -Argument '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass C:\Automation\removedupshortcut.ps1')
        Trigger = (New-ScheduledTaskTrigger -AtLogOn)
        Principal = (New-ScheduledTaskPrincipal -GroupId "System")
        TaskName = 'Remove Duplicate Shortcuts'
        Description = 'Remove Duplicate Shortcuts'
        }
        Register-ScheduledTask @Params
        Start-ScheduledTask -TaskName "Remove Duplicate Shortcuts"
    }
    else
    {
        Start-ScheduledTask -TaskName "Remove Duplicate Shortcuts"
        }
