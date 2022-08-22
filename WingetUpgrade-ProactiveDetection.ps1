<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.195
	 Created on:   	8/22/2022 3:08 PM
	 Created by:   	David Just
	 Website: 	davidjust.com
	 Filename: WingetUpgrade-ProactiveDetection.ps1    	
	===========================================================================
	.DESCRIPTION
		Proactive Remediation detection script for applications with updates
#>

$Blacklisted = @(
	'Microsoft.Teams'
	'Microsoft.Office'
	'Microsoft.VC++2015-2022Redist-x64'
)
Import-Module -Name WingetTools
$AvailableUpdates = Get-WGInstalled | where-object { $_.id -notin $Blacklisted -and $_.update }

if ($AvailableUpdates.count -gt 0)
{
	"There are applications with Updates available"
	$AvailableUpdates | Select-Object -Property Name, ID, InstalledVersion, OnlineVersion
	exit 1
}
else
{
	"There are no apps to update"
	Exit 0
}

