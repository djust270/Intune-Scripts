# This first section adds the registry keys for point and print. This allows standard users to install printers. 
# Enter the trusted printers by FQDN below
$printServers = @(
    "PrintServer1.domain.local"
    "PrintServer2.domain.local"	    
)
#endregion
#region PnP retrictions
$hklmKeys = @(
    [PSCustomObject]@{
        Name  = "Restricted"
        Type  = "DWORD"
        Value = "1"
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
    }
    [PSCustomObject]@{
        Name  = "TrustedServers"
        Type  = "DWORD"
        Value = "1"
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
    }
    [PSCustomObject]@{
        Name  = "InForest"
        Type  = "DWord"
        Value = "0"
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
    }
    [PSCustomObject]@{
        Name  = "NoWarningNoElevationOnInstall"
        Type  = "DWord"
        Value = "1"
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
    }
    [PSCustomObject]@{
        Name  = "UpdatePromptSettings"
        Type  = "DWord"
        Value = "2"
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
    }
    [PSCustomObject]@{
        Name  = "ServerList"
        Type  = "String"
        Value = $printServers -join ";"
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
	}
	[PSCustomObject]@{
		Name  = "RestrictDriverInstallationToAdministrators"
		Type  = "DWORD"
		Value = "0"
		Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
	}
)
$hklmKeys += [PSCustomObject]@{
    Name  = "PackagePointAndPrintServerList"
    Type  = "DWORD"
    Value = "1"
    Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PackagePointAndPrint"
}
foreach ($p in $printServers) {
    $hklmKeys += [PSCustomObject]@{
        Name  = $p
        Type  = "String"
        Value = $p
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PackagePointAndPrint\ListofServers"
    }
}

function Set-ComputerRegistryValues {
    param (
        [Parameter(Mandatory = $true)]
        [array]$RegistryInstance
    )
    try {
        foreach ($key in $RegistryInstance) {
            $keyPath = "$($key.Path)"
            if (!(Test-Path $keyPath)) {
                Write-Host "Registry path : $keyPath not found. Creating now." -ForegroundColor Green
                New-Item -Path $keyPath -Force | Out-Null
                Write-Host "Creating item property: $($key.Name)" -ForegroundColor Green
                New-ItemProperty -Path $keyPath -Name $key.Name -Value $key.Value -PropertyType $key.Type -Force
            }
            else {
                Write-Host "Creating item property: $($key.Name)" -ForegroundColor Green
                New-ItemProperty -Path $keyPath -Name $key.Name -Value $key.Value -PropertyType $key.Type -Force
            }
        }
    }
    catch {
        Throw $_.Exception.Message
    }
}
#endregion
Set-ComputerRegistryValues -RegistryInstance $hklmKeys

######################################################################################################################################################
# This next section creates a scheduled task to run as the logged on user. This will auto map the printers if they are not already mapped at user login
# Also added a trigger when a user connects to VPN using the built in Windows VPN client. 
#######################################################################################################################################################

$script= @'
if ((Get-Printer | where name -like "\\PrintServer1.domain.local\Printer1"))
{
exit
}
$fp01= Test-Connection -ComputerName PrintServer1.domain.local -Quiet
if ($fp01) {
add-printer -ConnectionName "\\PrintServer1.domain.local\Printer1"
add-printer -ConnectionName "\\PrintServer1.domain.local\Printer2"
}
ELSE
{
exit
}
'@

# Create a directory for our login script
if ( -not (Test-Path -Path c:\automation) )
 {
  new-item c:\automation -ItemType directory -force
 }
set-content c:\automation\addprinters.ps1 $script

if( -Not (Get-ScheduledTask -TaskName "Add Shared Printers" -ErrorAction SilentlyContinue -OutVariable task) )
    {
        $Params = @{
        Action = (New-ScheduledTaskAction -Execute 'powershell' -Argument '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass c:\automation\addprinters.ps1')
        Trigger = (New-ScheduledTaskTrigger -AtLogOn)
        Principal = (New-ScheduledTaskPrincipal -UserId (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -expand UserName))
        TaskName = 'Add Shared Printers'
        Description = 'Add Shared Printers'
    }
Register-ScheduledTask @Params

# Add trigger for connection to VPN
$CIMTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
$Trigger = @(
(New-CimInstance -CimClass $CIMTriggerClass -ClientOnly),
(New-ScheduledTaskTrigger -AtLogOn)
)
$Trigger[0].Subscription = 
@"
<QueryList><Query Id="0" Path="Application"><Select Path="Application">*[System[Provider[@Name='RasClient'] and EventID=20225]]</Select></Query></QueryList>
"@
$Trigger[0].Enabled = $True

Set-Scheduledtask "Add Shared Printers" -Trigger $Trigger

Start-ScheduledTask -TaskName "Add Shared Printers"
    }
    else
    {
$CIMTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
$Trigger = @(
(New-CimInstance -CimClass $CIMTriggerClass -ClientOnly),
(New-ScheduledTaskTrigger -AtLogOn)
)
$Trigger[0].Subscription = 
@"
<QueryList><Query Id="0" Path="Application"><Select Path="Application">*[System[Provider[@Name='RasClient'] and EventID=20225]]</Select></Query></QueryList>
"@
$Trigger[0].Enabled = $True

Set-Scheduledtask "Add Shared Printers" -Trigger $Trigger
        
Start-ScheduledTask -TaskName "Add Shared Printers"
        }

