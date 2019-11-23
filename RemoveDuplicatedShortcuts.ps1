#If you are enforcing One Drive Know File Move, redirecting the Desktop, its possible some shortcuts may be duplicated 
#between the time the computer enrolls in intune and one drive redirects the desktop. This script will clear up and remove any \
#duplicated shortcuts. Just add in the shortcut name and your companies One Drive path. 

$duplicateshortcuts = "shortcut1.lnk","shortcut2.lnk","shortcut3.lnk","microsoft edge.lnk" | foreach {test-path "$env:USERPROFILE\OneDrive - YOUR COMPANY\Desktop\$_."}
$OldShortcuts = @("$env:USERPROFILE\OneDrive - YOUR COMPANY\Desktop\shortcut1.lnk","$env:USERPROFILE\OneDrive - Park Hotels & Resorts\Desktop\shortcut2.lnk","$env:USERPROFILE\Onedrive - Park Hotels & Resorts\Desktop\shortcut3.lnk","$env:USERPROFILE\OneDrive - Park Hotels & Resorts\Desktop\Microsoft Edge.lnk")
if ($duplicateshortcuts -eq $true) 
{
Get-ChildItem $OldShortcuts | Remove-Item
}
