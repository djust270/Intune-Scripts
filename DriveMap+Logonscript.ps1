$gmapscript= '$computer = Test-Connection -ComputerName computer.domain.local -ErrorAction stop
if ($computer -eq $true) {
net use G: /delete
net use G: \\computer.domain.local\share }'

new-item c:\automation -ItemType directory -force
set-content c:\automation\Gdrivemap.ps1 $gmapscript

if( -Not (Get-ScheduledTask -TaskName "G Drive Map" -ErrorAction SilentlyContinue -OutVariable task) )
    {
        $Params = @{
        Action = (New-ScheduledTaskAction -Execute 'powershell' -Argument '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass c:\automation\Gdrivemap.ps1')
        Trigger = (New-ScheduledTaskTrigger -AtLogOn)
        Principal = (New-ScheduledTaskPrincipal -GroupId "System")
        TaskName = 'G Drive Map'
        Description = 'G Drive Map'
        }
        Register-ScheduledTask @Params
        Start-ScheduledTask -TaskName "G Drive Map"
    }
    else
    {
        Start-ScheduledTask -TaskName "G Drive Map"
        }