############## Set 3 daily Volume Shadow Copy Tasks #####################

if( -Not (Get-ScheduledTask -TaskName "Volume Shadow Copy C" -ErrorAction SilentlyContinue -OutVariable task) )
    {
        $Params = @{
        Action = (New-ScheduledTaskAction -Execute 'cmd' -Argument '/c /c "wmic shadowcopy call create Volume=c:\" ')
        Trigger = (New-ScheduledTaskTrigger -Daily -At 8am)
        Principal = (New-ScheduledTaskPrincipal -GroupId "System")
        TaskName = 'Volume Shadow Copy C'
        Description = 'Volume Shadow Copy C'
        }
        Register-ScheduledTask @Params
        Start-ScheduledTask -TaskName "Volume Shadow Copy C"
    }
    else
    {
        Start-ScheduledTask -TaskName "Volume Shadow Copy C"
        }

        if( -Not (Get-ScheduledTask -TaskName "Volume Shadow Copy C 2" -ErrorAction SilentlyContinue -OutVariable task) )
    {
        $Params = @{
        Action = (New-ScheduledTaskAction -Execute 'cmd' -Argument '/c /c "wmic shadowcopy call create Volume=c:\" ')
        Trigger = (New-ScheduledTaskTrigger -Daily -At 1PM)
        Principal = (New-ScheduledTaskPrincipal -GroupId "System")
        TaskName = 'Volume Shadow Copy C 2'
        Description = 'Volume Shadow Copy C 2'
        }
        Register-ScheduledTask @Params
        }

        if( -Not (Get-ScheduledTask -TaskName "Volume Shadow Copy C 3" -ErrorAction SilentlyContinue -OutVariable task) )
    {
        $Params = @{
        Action = (New-ScheduledTaskAction -Execute 'cmd' -Argument '/c /c "wmic shadowcopy call create Volume=c:\" ')
        Trigger = (New-ScheduledTaskTrigger -Daily -At 6PM)
        Principal = (New-ScheduledTaskPrincipal -GroupId "System")
        TaskName = 'Volume Shadow Copy C 3'
        Description = 'Volume Shadow Copy C 3'
        }
        Register-ScheduledTask @Params
              }
       
       ######## Set Max Shadow Copies 
        
        New-ItemProperty registry::HKLM\System\CurrentControlSet\Services\VSS\Settings -Name MaxShadowCopies -PropertyType DWORD -Value 16

        ############# Resize Shadow Storage max size
         vssadmin resize shadowstorage /for=C: /maxsize=5GB