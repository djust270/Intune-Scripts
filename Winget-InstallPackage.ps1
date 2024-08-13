<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.195
	 Created on:   	3/7/2022 2:14 PM
	 Created by:   	Dave Just
	 Organization: 	
	 Filename: Winget-InstallPackage.ps1
	 
	 Updated 07/15/2024 to support uninstallation, also handle scenario when WinGet is not installed
	 but package installation is requested during autopilot / oobe without a user account. Moved log location
	 to %programdata%\Microsoft\IntuneManagementExtension\Logs
	 
	 Updated 08/12/2024 to download and extract DesktopAppInstaller msixbundle to %ProgramData% if WinGet is not installed
	 This allows WinGet to function in SYSTEM context during OOBE/Autopilot when installation under user context is not possbile. 
	===========================================================================
.DESCRIPTION
	Installs any package within the WinGet public repository running as SYSTEM. Can be packaged and deployed as a Win32App in Intune
	Use as base for any install with WinGet. Simply specify the PackageID and log variables.

	If WinGet is not currently installed, a zipped copy will be extracted to the %PrograData% folder as installation in user context during OOBE/Autopilot was un-reliable. 
.PARAMETER PackageID
Specify the WinGet ID. Use WinGet Search "SoftwareName" to locate the PackageID
.PARAMETER PackageName
Specify the Package Name in place of PackageID if preferred. 
.PARAMETER Mode
Required parameter. Specify 'install' or 'uninstall' to perform that operation for the given package.
.PARAMETER Log
Required parameter. Specify the log file name. This will be logged to %programdata%\Microsoft\IntuneManagementExtension\Logs"
.PARAMETER AdditionalInstallArgs
Specify Additional Installation Arguments to pass to WinGet https://learn.microsoft.com/en-us/windows/package-manager/winget/install
    .EXAMPLE
powershell.exe -executionpolicy bypass -file Winget-InstallPackage.ps1 -PackageID "Google.Chrome" -Log "ChromeWingetInstall.log"
	.EXAMPLE
powershell.exe -executionpolicy bypass -file Winget-InstallPackage.ps1 -mode install -PackageID "Notepad++.Notepad++" -Log "NotepadPlusPlus.log"
	.EXAMPLE
powershell.exe -executionpolicy bypass -file Winget-InstallPackage.ps1 -PackageID "Python.Python.3.11" -mode uninstall -Log "Python3Install.log" -AdditionalInstallArgs "--architecture x64"
	.EXAMPLE
powershell.exe -executionpolicy bypass -file Winget-InstallPackage.ps1 -PackageName "Microsoft .NET Runtime 6.0" -mode install -Log "DotNetRuntime6.log"
#>

<#
TODO:
	Add function to download zipped WinGet copy from blob storage in the event that WinGet is not installed
	Extract to %ProgramData% folder
#>
param (
	[string]$PackageID = 'Notepad++.Notepad++',

	[string]$PackageName,
	
	[string]$AdditionalInstallArgs,
	
	[parameter()]
	[ValidateSet('Install','Uninstall')]
	# Set default mode to install
	[string]$Mode = 'Install',
	
	[parameter(Mandatory)]
	[string]$Log
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

function Write-Log($message) #Log script messages to temp directory
{
	$LogMessage = ((Get-Date -Format "MM-dd-yy HH:MM:ss ") + $message)
	if (Test-Path "$env:programdata\Microsoft\IntuneManagementExtension\Logs") {
	Out-File -InputObject $LogMessage -FilePath "$env:programdata\Microsoft\IntuneManagementExtension\Logs\$Log" -Append -Encoding utf8
	}
	Write-Host $message
}

function Download-Winget {
	<#
	.SYNOPSIS
	Download Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle and extract contents with 7zip cli to %ProgramData%
	#>
	$ProgressPreference = 'SilentlyContinue'
	$7zipFolder = "${env:WinDir}\Temp\7zip"
	try {
		Write-Log "Downloading WinGet..."
		# Create staging folder
		New-Item -ItemType Directory -Path "${env:WinDir}\Temp\WinGet-Stage" -Force
		# Download Desktop App Installer msixbundle
		Invoke-WebRequest -UseBasicParsing -Uri https://aka.ms/getwinget -OutFile "${env:WinDir}\Temp\WinGet-Stage\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
	}
	catch {
		Write-Log "Failed to download WinGet!"
		Write-Log $_.Exception.Message
		return
	}
	try {
		Write-Log "Downloading 7zip CLI executable..."
		# Create temp 7zip CLI folder
		New-Item -ItemType Directory -Path $7zipFolder -Force
		Invoke-WebRequest -UseBasicParsing -Uri https://www.7-zip.org/a/7zr.exe -OutFile "$7zipFolder\7zr.exe"
		Invoke-WebRequest -UseBasicParsing -Uri https://www.7-zip.org/a/7z2408-extra.7z -OutFile "$7zipFolder\7zr-extra.7z"
		Write-Log "Extracting 7zip CLI executable to ${7zipFolder}..."
		& "$7zipFolder\7zr.exe" x "$7zipFolder\7zr-extra.7z" -o"$7zipFolder" -y
	}
	catch {
		Write-Log "Failed to download 7zip CLI executable!"
		Write-Log $_.Exception.Message
		return
	}
	try {
	# Create Folder for DesktopAppInstaller inside %ProgramData%
	New-Item -ItemType Directory -Path "${env:ProgramData}\Microsoft.DesktopAppInstaller" -Force
	Write-Log "Extracting WinGet..."
	& "$7zipFolder\7za.exe" x "${env:WinDir}\Temp\WinGet-Stage\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -o"${env:WinDir}\Temp\WinGet-Stage" -y
	& "$7zipFolder\7za.exe" x "${env:WinDir}\Temp\WinGet-Stage\AppInstaller_x64.msix" -o"${env:ProgramData}\Microsoft.DesktopAppInstaller" -y
	}
	catch {
		Write-Log "Failed to extract WinGet!"
		Write-Log $_.Exception.Message
		return
	}
	if (-Not (Test-Path "${env:ProgramData}\Microsoft.DesktopAppInstaller\WinGet.exe")){
		Write-Log "Failed to extract WinGet!"
		exit 1
	}
	$Script:WinGet = "${env:ProgramData}\Microsoft.DesktopAppInstaller\WinGet.exe"
}

function Install-VisualC {
	try {
		$downloadurl = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
		$WebClient = New-Object System.Net.WebClient
		$WebClient.DownloadFile($downloadurl, "$env:Temp\vc_redist.x64.exe")
		$WebClient.Dispose()
	}
	catch {
		Write-Log "Failed to download Visual C++!"
		Write-Log $_.Exception.Message
	}
	# Check if another installation is in progress, then wait for it to complete
	$MSIExecCheck = Get-Process | Where-Object {$_.processname -eq 'msiexec'}
	if ($Null -ne $MSIExecCheck){
		Write-Log "another msi installation is in progress. Waiting for process to complete..."
		Wait-Process msiexec
		Write-Log "Continuing installation..."
	}
	try {
		$Install = start-process "$env:temp\vc_redist.x64.exe" -argumentlist "/q /norestart" -Wait -PassThru
		Write-Log "Installation completed with exit code $($Install.ExitCode)"
		return $Install.ExitCode
	}
	catch {
		Write-Log $_.Exception.Message
	}
	try {
		remove-item "$env:Temp\vc_redist.x64.exe"
	}
	catch {
		Write-Log "Failed to remove vc_redist.x64.exe after installation"
	}
}

function Get-RegUninstallKey
{
	param (
	[string]$DisplayName
	)
	$uninstallKeys = @(
		"registry::HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall"
		"registry::HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
		)
    $LoggedOnUser = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName
	if ($LoggedOnUser){
	$UserSID = ([System.Security.Principal.NTAccount](Get-CimInstance -ClassName Win32_ComputerSystem).UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value
    $UninstallKeys += @("registry::HKU\$UserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall" , "registry::HKU\$UserSID\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall")
	}
	$softwareTable =@()	
	foreach ($key in $uninstallKeys){
        if (-Not (Test-Path $Key)){
            Write-Warning "$Key not found"
            continue
        }
		$softwareTable += Get-Childitem $key | 
		ForEach-Object {
                try {
                Get-ItemProperty $_.pspath | Where-Object { $_.displayname } | Sort-Object -Property displayname
                }
                catch [System.InvalidCastException] {
                    # Ignore error as I was occasionally getting an invalid cast error on Get-ItemProperty
                }
		}
	}
	if ($DisplayName)
	{
		$softwareTable | Where-Object { $_.displayname -Like "*$DisplayName*" }
	}
	else
	{
		$softwareTable | Sort-Object -Property displayname -Unique
	}
	
}

function WingetInstallPackage {
param (
	$PackageID,
	$PackageName,
	$AdditionalInstallArgs
)
	# Check if another msi install is in progress and wait
	
	$MSIExecCheck = Get-Process | Where-Object {$_.processname -eq 'msiexec'}
	if ($Null -ne $MSIExecCheck){
		Write-Log "another msi installation is in progress. Waiting for process to complete..."
		Wait-Process msiexec
		Write-Log "Continuing installation..."
	}
	if ($PackageID){
		& $Winget install --id $PackageID --source Winget --silent $AdditionalInstallArgs --accept-package-agreements --accept-source-agreements 
	}
	elseif ($PackageName){
		& $Winget install --name $PackageName --source Winget --silent $AdditionalInstallArgs --accept-package-agreements --accept-source-agreements
	}
}

function Resolve-WinGetPath {
	# Look for Winget install in WindowsApps folder
	$WinAppFolderPath = Get-ChildItem -path "$env:ProgramFiles/WindowsApps" -recurse -filter "winget.exe" | where {$_.VersionInfo.FileVersion -ge 1.23}
	if ($WinAppFolderPath){
		$script:WinGet = $WinAppFolderPath | Select-Object -ExpandProperty Fullname | Sort-Object -Descending | Select-Object -First 1
		Write-Log "WinGet.exe found at path $Winget"
	}
	else {
		# Check if WinGet copy has already been extracted to ProgramData folder
		if (Test-Path "${env:ProgramData}\Microsoft.DesktopAppInstaller\WinGet.exe"){
			Write-Log "WinGet.exe found in ${env:ProgramData}\Microsoft.DesktopAppInstaller}"
			$Script:WinGet = "${env:ProgramData}\Microsoft.DesktopAppInstaller\WinGet.exe"		
		}
		else {
			# Download WinGet MSIX bundle and extract files to ProgramData folder
			Write-Log "WinGet.exe not found in ${env:ProgramData}\Microsoft.DesktopAppInstaller"
			Download-Winget
		}
	}
}

function Test-WinGetOutput {
	if (-Not (Test-Path $Winget)){
		Write-Log "WinGet path not found at Test-WinGetOutput function!"
		Write-Log "WinGet variable : $WinGet"
		exit 1
	}
	$OutputTest = & $WinGet
	if ([string]::IsNullOrEmpty($OutputTest)){
		Write-Log "WinGet executable test failed to produce output!"
		exit 1
	}
}

#endregion HelperFunctions
#region Script

$VisualC = Get-RegUninstallKey -DisplayName "Microsoft Visual C++ 2015-2022 Redistributable (x64)"

# Get path for Winget executible
Resolve-WinGetPath

# If Visual C++ Redist. not installed, install it
if (-Not $VisualC){ 
	Write-Log -message "Visual C++ X64 not found. Attempting to install" 
	try {
		$VisualCInstall = Install-VisualC
	}
	catch [System.InvalidOperationException]{
		Write-Log -message "Error installing visual c++ redistributable. Attempting install once more"
		Start-Sleep -Seconds 30
		$VisualCInstall = Install-VisualC
	}
	catch {
		Write-Log -message "Failed to install visual c++ redistributable!"
		Write-Log -message $_
		exit 1
	}	
	if ($VisualCInstall -ne 0){
		Write-Log -message "Visual C++ X64 install failed. Exit code : $VisualCInstall"
		exit 1
	}
		Test-WinGetOutput
}
try
	{
		switch ($Mode){
		'Install'{
				if ($PackageID){
				Write-Log -message "executing $Mode on $PackageID"
				$Install = WingetInstallPackage -PackageID $PackageID -AdditionalArgs $AdditionalInstallArgs	
				}
				elseif ($PackageName){
				Write-Log -message "executing $Mode on $PackageName"
				$Install = WingeInstallPackage -PackageName $PackageName -AdditionalArgs $AdditionalInstallArgs		
				}
				Write-Log $Install
			}
		'Uninstall'{
			if ($PackageID){
				Write-Log -message "executing $Mode on $PackageID"
				$Uninstall = & $Winget uninstall --id $PackageID --source WinGet --silent
			}
			elseif ($PackageName){
				Write-Log -message "executing $Mode on $PackageName"
				$Uninstall = & $Winget uninstall --name $PackageName --source WinGet --silent

			}
			Write-Log $Uninstall
		}
		}
	}
Catch
{
	Write-Log $error[0]
	exit 1
}
#endregion
