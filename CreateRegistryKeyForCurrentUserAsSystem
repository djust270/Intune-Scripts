#This script will load the HKU registry path for the current user and allow you to modify their hive as system/administrator
#This is sometimes needed as user may not have permission to create keys/write values to their HKCU hive

# Regex pattern for SIDs
$PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
 
# Get Username, SID, and location of ntuser.dat for all users
$ProfileList = gp 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.PSChildName -match $PatternSID} 
    
$UserSID = gci Registry::HKEY_USERS | ? {$_.PSChildname -match $PatternSID} | Select @{name="SID";expression={$_.PSChildName}} | select -ExpandProperty SID
$Path = "HKU\$UserSID\PATH_TO_KEY_TO_CREATE"
Reg Add $path /f
reg add $path /v DWORDNAME /t REG_DWORD /d 1 /f
