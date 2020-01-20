#Tests Connection to Print Server
$tpscript= '$fp01 = Test-Connection -ComputerName printserver.domain.com -ErrorAction SilentlyContinue

#Checks if driver is installed. Installed via win32 intune app using pnputil.exe
$toshiba= test-path C:\Windows\System32\DriverStore\FileRepository\esf6u.inf_amd64_10e58d367838d6a3

if ($toshiba -eq $true -and $fp01 -eq $true) 
{add-printer -ConnectionName "\\printserver.domain.com\Printer Share Name 1"
add-printer -ConnectionName "\\printserver.domain.com\Printer Share Name 2" 
add-printer -ConnectionName "\\printserver.domain.com\Printer Share Name 3" }'

#create mapping script
new-item c:\automation -ItemType directory -force
set-content c:\automation\addprinters.ps1 $tpscript

if( -Not (Get-ScheduledTask -TaskName "Map Printers" -ErrorAction SilentlyContinue -OutVariable task) )
    {
        $Params = @{
        Action = (New-ScheduledTaskAction -Execute 'powershell' -Argument '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass c:\automation\addprinters.ps1')
        Trigger = (New-ScheduledTaskTrigger -AtLogOn)
        Principal = (New-ScheduledTaskPrincipal -UserId (Get-CimInstance –ClassName Win32_ComputerSystem | Select-Object -expand UserName))
        TaskName = 'Map Printers'
        Description = 'Map Printers'
        }
        Register-ScheduledTask @Params
        Start-ScheduledTask -TaskName "Map Printers"
    }
    else
    {
        Start-ScheduledTask -TaskName "Map Printers"
        }

