<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.195
	 Created on:   	8/22/2022 9:30 AM
	 Created by:   	David Just	
	 Filename: Install-WingetTools  	
	===========================================================================
	.DESCRIPTION
		This script will Install Winget and the WingetTools PowerShell module. 
#>

#region functions
function Install-VisualC #Install VisualC++ 2015-2022 x64
{
	$url = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
	$WebClient = New-Object System.Net.WebClient
	$WebClient.DownloadFile('https://aka.ms/vs/17/release/vc_redist.x64.exe', "$env:Temp\vc_redist.x64.exe")
	$WebClient.Dispose()
	start-process "$env:temp\vc_redist.x64.exe" -argumentlist "/q /norestart" -Wait
}

function Get-RegUninstallKey #Enumerate registry uninstall keys
{
	param (
		[string]$DisplayName
	)
	$ErrorActionPreference = 'Continue'
	$uninstallKeys = "registry::HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall", "registry::HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall", "registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall"
	$softwareTable = @()
	
	foreach ($key in $uninstallKeys)
	{
		$softwareTable += Get-Childitem $key | Get-ItemProperty | where displayname | Sort-Object -Property displayname
	}
	if ($DisplayName)
	{
		$softwareTable | where displayname -Like "*$DisplayName*"
	}
	else
	{
		$softwareTable | Sort-Object -Property displayname -Unique
	}
	
}

function Install-WingetTools #Install the WingetTools module.
{
	Install-PackageProvider -Name NuGet -Force
	Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
	Install-Module -Name WingetTools
	if (-Not [bool](Get-Module -ListAvailable -Name WingetTools))
	{
		$GithubURL = "https://github.com/djust270/WingetTools/archive/refs/heads/main.zip"
		$WebClient = [System.Net.WebClient]::new()
		$WebClient.DownloadFile($GithubURL, "$Env:TEMP\WingetTools.zip")
		Expand-Archive -Path "$Env:TEMP\WingetTools.zip" -DestinationPath "$env:windir\System32\WindowsPowerShell\v1.0\Modules"
		Rename-Item -Path "$env:windir\System32\WindowsPowerShell\v1.0\Modules\WingetTools-main" -NewName "WingetTools"
	}
}

function Install-WingetAsSystem # Install WinGet as logged on user by creating a scheduled task
{
	$script = @'
$releases_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$releases = Invoke-RestMethod -uri "$($releases_url)"
$latestRelease = $releases.assets | Where { $_.browser_download_url.EndsWith("msixbundle") } | Select -First 1
Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
Add-AppxPackage -Path $latestRelease.browser_download_url
'@
	if (!(test-path "$env:systemdrive\automation")) { mkdir "$env:systemdrive\automation" }
	$script | out-file "$env:systemdrive\automation\script.ps1"
	$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-executionpolicy bypass -WindowStyle minimized -file %HOMEDRIVE%\automation\script.ps1"
	$trigger = New-ScheduledTaskTrigger -AtLogOn
	$principal = New-ScheduledTaskPrincipal -UserId (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -expand UserName)
	$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
	Register-ScheduledTask RunScript -InputObject $task
	Start-ScheduledTask -TaskName RunScript
	Start-Sleep -Seconds 120
	Unregister-ScheduledTask -TaskName RunScript -Confirm:$false
	Remove-Item C:\automation\script.ps1
	
}


function Write-Log($message) #Log script messages to temp directory
{
	$LogMessage = ((Get-Date -Format "MM-dd-yy HH:MM:ss ") + $message)
	Out-File -InputObject $LogMessage -FilePath "$LogPath\$LogFullName" -Append -Encoding utf8
}

#endregion
#region pre-requsites
$LogName = 'WinGetToolsInstall'
$LogDate = Get-Date -Format dd-MM-yy_HH-mm # go with the EU format day / month / year
$LogFullName = "$LogName-$LogDate.log"
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"

$InstalledModules = Get-Module -ListAvailable
$WinGetToolsInstalled = [bool]($InstalledModules | Where-Object name -EQ "WingetTools")
$ThreadJobInstalled = [bool]($InstalledModules | Where-Object name -EQ "ThreadJob")

if (-Not $WinGetToolsInstalled) { Install-WingetTools } # Install WingetTools if not available

if (-Not $ThreadJobInstalled) # Install ThreadJob module if not installed
{
	Install-PackageProvider Nuget -Force
	Set-PackageSource -Name PSGallery -Trusted
	Install-Module -Name threadjob
}

Set-ExecutionPolicy bypass -Scope Process -Force
Import-Module WingetTools
$WingetPath = Get-WingetPath
$VisualC = Get-RegUninstallKey -DisplayName "Microsoft Visual C++ 2015-2022 Redistributable (x64)"
$loggedOnUser = (Get-CimInstance win32_computersystem).username

# If Visual C++ Redist. not installed, install it
if (!$VisualC)
{
	Write-Log -message "Visual C++ X64 not found. Attempting to install"
	try
	{
		Install-VisualC
	}
	Catch [System.InvalidOperationException]{
		Write-Log -message "Error installing visual c++ redistributable. Attempting install once more"
		Start-Sleep -Seconds 5
		Install-VisualC
	}
	Catch
	{
		Write-Log -message "Failed to install visual c++ redistributable!"
		Write-Log -message $_
		exit 1
	}
	$VisualC = Get-RegUninstallKey -DisplayName "Microsoft Visual C++ 2015-2022 Redistributable (x64)"
	if (-Not $VisualC) { Write-Log -message "Visual C++ Redistributable not found!"; exit 1 }
	else { Write-Log -message "Successfully installed Microsoft Visual C++ 2015-2022 Redistributable (x64)" }
}

if (-Not $WingetPath)
{
	if ($loggedOnUser)
	{
		Write-Log -message "Attempting to install Winget as System under $($loggedOnUser)"
		Install-WingetAsSystem
		# If more than one version of Winget, select the latest
		$WingetPath = Get-WingetPath
		if ($WingetPath.count -gt 1) { $WingetPath = $Winget[-1] }
		if (-Not $WingetPath) { "Winget not found after attempting install as system. Exiting."; exit 1 }
	}
}

