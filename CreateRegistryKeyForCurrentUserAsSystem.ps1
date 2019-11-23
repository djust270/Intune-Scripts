#This script will load the HKU registry path for the current user and allow you to modify their hive as system/administrator
#This is sometimes needed as user may not have permission to create keys/write values to their HKCU hive

$UserSID = (New-Object -ComObject Microsoft.DiskQuota).TranslateLogonNameToSID((Get-WmiObject -Class Win32_ComputerSystem).Username)

$Path = "HKU\$UserSID\PATH_TO_KEY_TO_CREATE"
Reg Add $path /f
reg add $path /v DWORDNAME /t REG_DWORD /d 1 /f
