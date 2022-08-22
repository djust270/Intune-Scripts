<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.195
	 Created on:   	8/22/2022 10:46 AM
	 Created by:   	David Just
	 Website: david.just.com
	 Filename: WingetUpgrade-Remediation.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
function Write-Log($message) #Log script messages to temp directory
{
	$LogMessage = ((Get-Date -Format "MM-dd-yy HH:MM:ss ") + $message)
	Out-File -InputObject $LogMessage -FilePath "$LogPath\$Log" -Append -Encoding utf8
}

$LogName = 'WinGetPackageUpgrade'
$LogDate = Get-Date -Format dd-MM-yy_HH-mm # go with the EU format day / month / year
$Log = "$LogName-$LogDate.log"
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
Import-Module WingetTools

# Add any apps you do not wish to get updated here (for instance apps that auto-update). Use the Winget ID
$Blacklisted = @(
	'Microsoft.Teams'
	'Microsoft.Office'
	'Microsoft.VC++2015-2022Redist-x64'
)
$AvailableUpdates = Get-WGInstalled | where-object { $_.id -notin $Blacklisted -and $_.update }
Write-Log -message "Packages with Updates Available:"
$AvailableUpdates | select Name, Version | Out-File -FilePath "$logpath\$Log" -Append -Encoding utf8


foreach ($App in $AvailableUpdates) # Invoke upgrade for each updatable app and log results
{
	[void](Get-Process | Where-Object { $_.name -Like "*$App.Name*" } | Stop-Process -Force)
	$UpgradeRun = & $WingetPath upgrade --id $App.id -h --accept-package-agreements --accept-source-agreements
	$UpgradeRun | Out-File -FilePath "$logpath\$log" -Append -Encoding utf8
	$Status = [bool]($UpgradeRun | select-string -SimpleMatch "Successfully installed")
	if ($Status -eq $true)
	{
		$Success += $App
	}
	else
	{
		$Failed += $App
	}
	
}


if ($Success.count -gt 0)
{
	Write-Log -message "Successful Upgraded the following:"
	$Success | Out-File -FilePath "$logpath\$log" -Append -Encoding utf8
	"Sucessfully Updated the following apps:`n{0}" -f $($Success | Select-Object -Property name)
}

if ($Failed.count -gt 0)
{
	Write-Log -message "Failed to Upgrade the following:"
	$Failed | Out-File -FilePath "$logpath\$log" -Append -Encoding utf8
}
