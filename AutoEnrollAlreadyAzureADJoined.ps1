<#
Create a scheduled task and apply registry keys to force auto enrollment to MDM for already
AzureAD joined devices. These are the same actions applied when applying the Auto enroll MDM GPO settings. 
#>
$RegKey ="HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\"

$RegKey1 ="HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM"

$ScheduleName ="Schedule created by enrollment client for automatically enrolling in MDM from AAD"

$Date = Get-Date -Format "yyyy-MM-dd"

$Time = (Get-date).AddMinutes(5).ToString("HH:mm:ss")

 

$ST = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Author>Microsoft Corporation</Author>
    <URI>\Microsoft\Windows\EnterpriseMgmt\Schedule created by enrollment client for automatically enrolling in MDM from AAD</URI>
    <SecurityDescriptor>D:P(A;;FA;;;BA)(A;;FA;;;SY)(A;;FRFX;;;LS)</SecurityDescriptor>
  </RegistrationInfo>
  <Triggers>
    <TimeTrigger>
      <Repetition>
        <Interval>PT5M</Interval>
        <Duration>P1D</Duration>
        <StopAtDurationEnd>true</StopAtDurationEnd>
      </Repetition>
      <StartBoundary>$($Date)T$($Time)</StartBoundary>
      <Enabled>true</Enabled>
    </TimeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>Queue</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT1H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>%windir%\system32\deviceenroller.exe</Command>
      <Arguments>/c /AutoEnrollMDM</Arguments>
    </Exec>
  </Actions>
</Task>
 
"@



 

New-Item -Path $RegKey -Name MDM

New-ItemProperty -Path $RegKey1 -Name AutoEnrollMDM -Value 1

New-ItemProperty -Path $RegKey1 -Name UseAADCredentialType -Value 1

(Register-ScheduledTask -XML $ST -TaskName $ScheduleName -Force) | Out-null