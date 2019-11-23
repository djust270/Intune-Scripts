#This section creates our layoutmodification xml

$layout = '<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout">
  <LayoutOptions StartTileGroupCellWidth="6" />
  <DefaultLayoutOverride>
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6">
        <start:Group Name="">
          <start:Tile Size="2x2" Column="0" Row="0" AppUserModelID="Microsoft.CompanyPortal_8wekyb3d8bbwe!App" />
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="2" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Word.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="2" Row="4" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="4" Row="2" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Excel.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="2" Row="2" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk" />
          <start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Outlook.lnk" />
          <start:Tile Size="2x2" Column="0" Row="4" AppUserModelID="Microsoft.Office.OneNote_8wekyb3d8bbwe!microsoft.onenoteim" />
        </start:Group>
      </defaultlayout:StartLayout>
    </StartLayoutCollection>
  </DefaultLayoutOverride>
<CustomTaskbarLayoutCollection PinListPlacement="Replace">      
	<defaultlayout:TaskbarLayout>
        <taskbar:TaskbarPinList>
          <taskbar:UWA AppUserModelID="Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge" />
          <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk" />
	  <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Word.lnk" />
	  <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Outlook.lnk" />
	  <taskbar:DesktopApp DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Excel.lnk" />
	  <taskbar:DesktopApp DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" />
        </taskbar:TaskbarPinList>
      </defaultlayout:TaskbarLayout>
    </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>'
    
    $UserSID = (New-Object -ComObject Microsoft.DiskQuota).TranslateLogonNameToSID((Get-WmiObject -Class Win32_ComputerSystem).Username)
    $Path = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Profilelist\$UserSID"
    $UserPath = Get-ItemProperty "Registry::$path" -name "ProfileImagePath" | select -ExpandProperty ProfileImagePath
    
         Set-content $userpath\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml $layout -Force
    
    #This Section Creates the powershell script that will be used by our scheduled task and save to c:\automation

    $content = 'New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
    $UserSID = (New-Object -ComObject Microsoft.DiskQuota).TranslateLogonNameToSID((Get-WmiObject -Class Win32_ComputerSystem).Username)
    $Path = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Profilelist\$UserSID"
    $UserPath = Get-ItemProperty "Registry::$path" -name "ProfileImagePath" | select -ExpandProperty ProfileImagePath
    $time = Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
    
    #This Modifies the time stamp of the layoutmodification xml
    
    Get-Item $userpath\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml | % {$_.CreationTime = $time}
    Get-Item $userpath\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml | % {$_.LastWriteTime = $time}    
    
    # Remove-Item HKU:\$UserSID\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\*$start.tilegrid$windows.data.curatedtilecollection.tilecollection  -Force -Recurse
      Remove-Item HKU:\$UserSID\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store -Force -recurse
    Get-Process Explorer | Stop-Process -force
    
    sleep 5
    
    $explorer = get-process explorer
    
    if ($explorer -eq $false)
    {
    start-process explorer
    }
    remove-psdrive -Name HKU'

    new-item c:\automation -ItemType directory -force
    set-content c:\automation\startlayout.ps1 $content

    #This Section Creates the Scheduled task to run our startlayout script

    if( -Not (Get-ScheduledTask -TaskName "Start Menu Layout" -ErrorAction SilentlyContinue -OutVariable task) )
    {
        $Params = @{
        Action = (New-ScheduledTaskAction -Execute 'powershell' -Argument '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass C:\Automation\startlayout.ps1')
        Trigger = (New-ScheduledTaskTrigger -once -At ([DateTime]::Now.AddMinutes(1)) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Hours 3))
        Principal = (New-ScheduledTaskPrincipal -GroupId "System")
        TaskName = 'Start Menu Layout'
        Description = 'Start Menu Layout'
        }
        Register-ScheduledTask @Params
        Start-ScheduledTask -TaskName "Start Menu Layout"
    }
    else
    {
        Start-ScheduledTask -TaskName "Start Menu Layout"
        }
