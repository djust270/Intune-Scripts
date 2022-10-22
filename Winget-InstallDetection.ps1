<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.195
	 Created on:   	3/7/2022 2:14 PM
	 Created by:   	Dave Just
	 Organization: 	
	 Filename: WingetInstallDetection.ps1   	
	===========================================================================
.DESCRIPTION
	Simple Win32App detection script. Detects the presence of an uninstall key matching the displayname of the variable $SoftwareName. 
	If a key is matched, return to Intune that the software is installed. 
.EXAMPLE
$SoftwareName = 'Chrome' # Search for an uninstall key with Displayname 'Chrome' for Google Chrome
#>
# Edit the software displayname below

$SoftwareName = ''

function Get-RegUninstallKey
{
	param (
		[string]$DisplayName
	)
	$ErrorActionPreference = 'Continue'
	$UserSID = ([System.Security.Principal.NTAccount](Get-CimInstance Win32_ComputerSystem).UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value
	$uninstallKeys = "registry::HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall", "registry::HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall","registry::HKU\$UserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall"
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

$UninstallKey = Get-RegUninstallKey -DisplayName $SoftwareName
if ($UninstallKey)
{
	Write-Output "$($SoftwareName) is installed"
	exit 0
}
else
{
	exit 1
}
