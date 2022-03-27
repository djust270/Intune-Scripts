<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.195
	 Created on:   	3/7/2022 2:14 PM
	 Created by:   	Dave Just
	 Organization: 	
	 Filename: Winget-InstallPackage.ps1   	
	===========================================================================
.DESCRIPTION
	Installs any package within the WinGet public repository running as SYSTEM. Can be packaged and deployed as a Win32App in Intune
	Use as base for any install with WinGet. Simply specify the PackageID and log variables. 
.PARAMETER PackageID
Specify the WinGet ID. Use WinGet Search "SoftwareName" to locate the PackageID
    .EXAMPLE
powershell.exe -exectuionpolicy bypass -file  Winget-InstallPackage.ps1 -PackageID "Google.Chrome" -Log "ChromeWingetInstall.log"
	.EXAMPLE
powershell.exe -executionpolicy bypass -file Winget-InstallPackage.ps1 -PackageID "Notepad++.Notepad++" -Log "NotepadPlusPlus.log"
#>
param (
	$PackageID,
	$Log
)

# Re-launch as 64bit process (source: https://z-nerd.com/blog/2020/03/31-intune-win32-apps-powershell-script-installer/)
$argsString = ""
If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64")
{
	Try
	{
		foreach ($k in $MyInvocation.BoundParameters.keys)
		{
			switch ($MyInvocation.BoundParameters[$k].GetType().Name)
			{
				"SwitchParameter" { if ($MyInvocation.BoundParameters[$k].IsPresent) { $argsString += "-$k " } }
				"String"          { $argsString += "-$k `"$($MyInvocation.BoundParameters[$k])`" " }
				"Int32"           { $argsString += "-$k $($MyInvocation.BoundParameters[$k]) " }
				"Boolean"         { $argsString += "-$k `$$($MyInvocation.BoundParameters[$k]) " }
			}
		}
		Start-Process -FilePath "$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -ArgumentList "-File `"$($PSScriptRoot)\Winget-InstallPackage.ps1`" $($argsString)" -Wait -NoNewWindow
	}
	Catch
	{
		Throw "Failed to start 64-bit PowerShell"
	}
	Exit
}

#region HelperFunctions
function InstallWingetAsSystem # Install WinGet as logged on user by creating a scheduled task
{
	$script = @'
$releases_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$releases = Invoke-RestMethod -uri "$($releases_url)"
$latestRelease = $releases.assets | Where { $_.browser_download_url.EndsWith("msixbundle") } | Select -First 1
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
	Out-File -InputObject $LogMessage -FilePath "$Env:Temp\$Log" -Append -Encoding utf8
}

function WingetTempDownload # Download WinGet from blob storage if unable to install
{
	$WebClient = New-Object System.Net.WebClient
	try
	{
		$WebClient.DownloadFile('https://djstorage2.blob.core.windows.net/scriptsupport/WinGet.zip', "$env:Temp\WinGet.zip")
		$WebClient.Dispose()
	}
	Catch
	{
		Write-Log $error
	}
	
	try
	{
		mkdir "$env:TEMP\WingetTemp" -Force
		Expand-Archive "$env:TEMP\WinGet.zip" -destination "$Env:Temp\WingetTemp" -Force -ErrorAction 'Stop'
		$global:Winget = "$Env:TEMP\WinGetTemp\Winget\AppInstallerCLI.exe"
	}
	Catch
	{
		Write-Log $Error
	}
		
	$WebClient.Dispose()
}

function WingetRun {
param (
	$PackageID,
	$RunType,
	$Winget
)
	& $Winget $RunType --id $PackageID --source Winget --silent --accept-package-agreements --accept-source-agreements 
}




#endregion HelperFunctions
#region Script

$loggedOnUser = (gcim win32_computersystem).username
# Get path for Winget executible
$Winget = gci "$env:ProgramFiles\WindowsApps" -Recurse -File | where { $_.name -like "AppInstallerCLI.exe" -or $_.name -like "Winget.exe" } | select -ExpandProperty fullname
# If there are multiple versions, select latest
if ($Winget.count -gt 1) { $Winget = $Winget[-1] }
$WingetTemp = gci $env:TEMP -Recurse -File | where name -like AppInstallerCLI.exe | select -ExpandProperty fullname
# Try to install Winget if not already installed
if (!($Winget))
{
	if ($loggedOnUser)
	{
		Write-Log -message "Attempting to install Winget as System under $($loggedOnUser)"
		InstallWingetAsSystem
		$Winget = gci "C:\Program Files\WindowsApps" -Recurse -File | where { $_.name -like "AppInstallerCLI.exe" -or $_.name -like "Winget.exe" } | select -ExpandProperty fullname
		# If more than one version of Winget, select the latest
		if ($Winget.count -gt 1) { $Winget = $Winget[-1] }
		# If WinGet is not found, download copy from Blob storage
		if (!$Winget){ WingetTempDownload }
		try
		{
			$Install = WingetRun -Winget $Winget -RunType install -PackageID $PackageID
			Write-Log $Install
		}
		Catch
		{
			Write-Log $error[0]
			exit 1
		}
		
	}
	else
	{
		try
		{
			
			Write-Log "Winget not found, attempting to download now to $($env:TEMP)"
			WingetTempDownload
			try
			{
				$Install = WingetRun -Winget $Winget -RunType install -PackageID $PackageID
				Write-Log $Install
			}
			Catch
			{
				Write-Log $error
				exit 1
			}
			
		}
		Catch
		{
			Write-Log "Unable to initialize Winget. Exiting"
			Write-Output $Error
			exit 1
		}
	}
	
	
}
else
{
	Write-Log "Winget found at $($Winget)"
	$Install = WingetRun -Winget $Winget -RunType install -PackageID $PackageID
	Write-Log $Install
}
#endregion


