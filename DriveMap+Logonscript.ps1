$ServerName = #Enter the FQDN of the file server
$DriveLetter = #Enter drive letter
$TaskName = $DriveLetter + " Drive Map"
$UNCPath = #Enter UNC file path for fileshare

$tasks = get-scheduledtask -taskpath '\' | select -ExpandProperty taskname
if ($tasks -like $TaskName){Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false ; write-host "Task Unregistered" }
$gmapscript= @"
sleep 20
`$fp01 = Test-Connection -ComputerName $ServerName -ErrorAction SilentlyContinue
`$UNCPath = $UNCPath
if (`$fp01) {
net use $($DriveLetter): /delete
net use $($DriveLetter): `$UNCPath
}
"@
if ( -not (Test-Path -Path c:\automation) )
  {
new-item c:\automation -ItemType directory -force
 }
set-content c:\automation\$($DriveLetter + 'drivemap.ps1') $gmapscript

$action = New-ScheduledTaskAction -Execute 'powershell' -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Minimized -File $($DriveLetter + 'drivemap.ps1')"
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId (Get-CimInstance –ClassName Win32_ComputerSystem | Select-Object -expand UserName)
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
Register-ScheduledTask $TaskName -InputObject $task
Start-ScheduledTask -TaskName $TaskName
