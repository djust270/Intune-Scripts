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
		foreach {
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
