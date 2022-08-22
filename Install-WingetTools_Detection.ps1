<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.195
	 Created on:   	8/22/2022 10:14 AM
	 Created by:   	David Just
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		Detection script for Install-WingetTools
#>

$WingetTools = [bool](Get-Module -ListAvailable -Name WingetTools)
if ($WingetTools)
{
	"WingetTools is installed"
	exit 0
}
else
{
	"WingetTools is not installed!"
	exit 1
}
