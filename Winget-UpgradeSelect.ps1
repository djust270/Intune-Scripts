<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.195
	 Created on:   	1/18/2022 8:39 AM
	 Created by:   	Dave Just
	 Organization: 	
	 Filename: Winget-UpgradeSelect.ps1    	
	===========================================================================
	.DESCRIPTION
		Use the Windows Package Manager (Winget) to selectively install application updates. Edit the WinGetApprovedPackages hashtables with the packages 
    you would like to keep updated
#>
param (
[string]$ClientName	
)
$LogName = 'WinGetPackageUpgrade'
$LogDate = (Get-Date).ToFileTime()
$Log = "$LogName-$LogDate.log"
$results = [System.Collections.Generic.List[PsObject]]::new()
$loggedOnUser = (GCIM Win32_ComputerSystem).Username

#region HelperFunctions

function Get-RegUninstallKey #List all system-wide installed software
{
	param (
		[string]$DisplayName
	)
	$ErrorActionPreference = 'SilentlyContinue'
	$UserSID = ([System.Security.Principal.NTAccount](Get-CimInstance -ClassName Win32_ComputerSystem).UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value
	$uninstallKeys = "registry::HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall", "registry::HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
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
		$softwareTable | Sort-Object -Unique
	}
	Return $softwareTable
	
}

function LogWrite($message) #Log script messages
{
	$LogMessage = ((Get-Date -Format "MM-dd-yy HH:MM:ss ") + $message)
	Out-File -InputObject $message -FilePath "$env:TEMP\$Log" -Append -Encoding utf8
	#[System.IO.File]::AppendAllText("$env:TEMP\$Log","`n $($LogMessage)")
}

function InstallWinget # Install WinGet as logged on user
{
	$script = @'
$hasPackageManager = Get-AppPackage -name "Microsoft.DesktopAppInstaller"

	if(!$hasPackageManager)
	{
		$releases_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"

		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		$releases = Invoke-RestMethod -uri "$($releases_url)"
		$latestRelease = $releases.assets | Where { $_.browser_download_url.EndsWith("msixbundle") } | Select -First 1
	
		Add-AppxPackage -Path $latestRelease.browser_download_url
	}
'@
	if (!(test-path C:\automation)) { mkdir C:\automation }
	$script | out-file C:\automation\script.ps1
	$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-executionpolicy bypass -file C:\automation\script.ps1"
	$trigger = New-ScheduledTaskTrigger -AtLogOn
	$principal = New-ScheduledTaskPrincipal -UserId (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -expand UserName)
	$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
	Register-ScheduledTask RunScript -InputObject $task
	Start-ScheduledTask -TaskName RunScript
	Start-Sleep -Seconds 2
	Unregister-ScheduledTask -TaskName RunScript -Confirm:$false
	Remove-Item C:\automation\script.ps1

# Get path for Winget executible
$Global:Winget = gci "C:\Program Files\WindowsApps" -Recurse -File | where {$_.name -like "AppInstallerCLI.exe" -or $_.name -like "WinGet.exe"} | select -ExpandProperty fullname

# If there are multiple versions, select latest
if ($Winget.count -gt 1){$Winget = $Winget[-1]}
if (!($Winget)){LogWrite "AppInstallerCLI.exe not found after InstallWinget function. Aborting!"
Write-Output "AppInstallerCLI.exe not found after InstallWinget function. Aborting!"
Exit 1}

}


#endregion HelperFunctions

#region Script


# Get path for Winget executible
$Winget = gci "C:\Program Files\WindowsApps" -Recurse -File | where {$_.name -like "AppInstallerCLI.exe" -or $_.name -like "WinGet.exe"} | select -ExpandProperty fullname
# If there are multiple versions, select latest
if ($Winget.count -gt 1){$Winget = $Winget[-1]}
$WingetTemp = gci $env:TEMP -Recurse -File | where name -like AppInstallerCLI.exe | select -ExpandProperty fullname
# Try to install Winget if not already installed
if (!($Winget))
	{
	if ($WingetTemp) { LogWrite "Winget found in $($env:TEMP)";$Winget = $WingetTemp }
	elseif ($loggedOnUser) { InstallWinget }
	else	
	{
		try
		{
			
			LogWrite "Winget not found, attempting to download now to $($env:TEMP)"
			$WebClient = New-Object System.Net.WebClient
			$WebClient.DownloadFile('https://djstorage2.blob.core.windows.net/scriptsupport/WinGet.zip', "$env:Temp\WinGet.zip")
			$WebClient.Dispose()
			Expand-Archive $env:TEMP\WinGet.zip -destination $Env:Temp
			$Winget = "$Env:TEMP\WinGet\AppInstallerCLI.exe"
		}
		Catch
		{
			LogWrite "Unable to initialize Winget. Exiting"
			Write-Output $Error[0]
			exit 1
		}
	}
	
}

$Winrar = (Get-RegUninstallKey | where displayname -Like "*WinRAR*" | select -ExpandProperty Displayname)
if (!($Winrar)) { $Winrar = "Null-1" }
$7Zip = (Get-RegUninstallKey | where displayname -Like "*7-zip*" | select -ExpandProperty Displayname)
if (!($7zip)) { $7zip = "Null-2" }

# Hash table to translate installed software to Winget Package IDs
$WinGetApprovedPackages = @{
	'Google Chrome'			      = 'Google.Chrome'
	'Mozilla Firefox (x64 en-US)' = 'Mozilla.Firefox'
	'Microsoft OneDrive'		  = 'Microsoft.OneDrive'
	'Notepad++'				      = 'Notepad++.Notepad++'
	'Microsoft Edge'			  = 'Microsoft.Edge'
	'Lenovo System Update'	      = 'Lenovo.SystemUpdate'
	"$($7Zip)"				      = '7zip.7zip'
	"$($WinRar)"				  = 'RARLab.WinRAR'	
	"Adobe Acrobat Reader DC"     = 'Adobe.Acrobat.Reader.32-bit'
	"CCleaner"				      = "Piriform.CCleaner"
	"PuTTY"					      = "PuTTY.PuTTY"	
}

$InstalledSoftware = Get-RegUninstallKey
$UpgradeList = foreach ($Package in $WinGetApprovedPackages.Keys) { $InstalledSoftware | where displayname -Like $Package }

LogWrite "Client: $($ClientName)"
LogWrite "Hostname: $($env:COMPUTERNAME)"
LogWrite "Found the following installed packages:"
$UpgradeList | foreach {LogWrite "Name: $($_.Displayname) Version: $($_.DisplayVersion)"}

# Index software displaynames in hash table
$WingetPackages = $WinGetApprovedPackages[$UpgradeList.DisplayName]

# Remove null values from array
$WingetPackages = $WinGetPackages | where { $_ }

# Run the upgrade command for installed software only based on our package list
foreach ($Package in $WinGetPackages)
{
	LogWrite "Upgrading $($Package)"
	try
	{
		$UpgradeRun = & $Winget upgrade --id $Package -h --accept-package-agreements --accept-source-agreements | Tee-Object "$env:TEMP\$log" -Append
	}
	Catch
	{
		LogWrite $Error[0]
		Write-Output $Error[0]
	}
	
}
# Adding Hashtable here again as 7zip and Winrar have the version number in the displayname
# Need the new displayname to compare to the old

$Winrar = (Get-RegUninstallKey | where displayname -Like "*WinRAR*" | select -ExpandProperty Displayname)
if (!($Winrar)) { $Winrar = "Null-1" }
$7Zip = (Get-RegUninstallKey | where displayname -Like "*7-zip*" | select -ExpandProperty Displayname)
if (!($7zip)) { $7zip = "Null-2" }

# Hash table to translate installed software to Winget Package IDs
$WinGetApprovedPackages = @{
	'Google Chrome'			      = 'Google.Chrome'
	'Mozilla Firefox (x64 en-US)' = 'Mozilla.Firefox'
	'Microsoft OneDrive'		  = 'Microsoft.OneDrive'
	'Notepad++'				      = 'Notepad++.Notepad++'
	'Microsoft Edge'			  = 'Microsoft.Edge'
	'Lenovo System Update'	      = 'Lenovo.SystemUpdate'
	"$($7Zip)"				      = '7zip.7zip'
	"$($WinRar)"				  = 'RARLab.WinRAR'
	"Adobe Acrobat Reader DC"	  = 'Adobe.Acrobat.Reader.32-bit'
	"CCleaner"				      = "Piriform.CCleaner"
	"PuTTY"					      = "PuTTY.PuTTY"
}



$InstalledSoftware = Get-RegUninstallKey
$PostUpgradeList = foreach ($Package in $WinGetApprovedPackages.Keys) { $InstalledSoftware | where displayname -Like $Package }

#Compare results
$UpgradeListHash = @{ }
$PostUpgradeHash = @{ }
foreach ($i in $UpgradeList) { $UpgradeListHash.Add($i.displayname , $i.displayversion) }
foreach ($i in $PostUpgradeList) { $PostUpgradeHash.Add($i.displayversion, $i.displayname) }
$compare = Compare-Object $UpgradeList.displayversion -DifferenceObject $PostUpgradeList.displayversion | where sideindicator -eq "=>" | select -ExpandProperty InputObject
if ($compare) { $UpgradedSoftware = $PostUpgradeHash[$compare] }

# Log what software was updated and create custom object
if (!($UpgradedSoftware))
{
	LogWrite "No software was eligable for upgrade"
}

else{
	foreach ($i in $compare)
	{
		$SoftwareName = $PostUpgradeHash[$i]
		if ($SoftwareName -match "7-Zip*")
		{
			$OldVersion = $UpgradeList | where displayname -Like "7-zip*" | select -ExpandProperty displayversion
		}
		elseif ($SoftwareName -match "WinRAR*")
		{
			$OldVersion = $UpgradeList | where displayname -Like "WinRAR*" | select -ExpandProperty displayversion
		}
		else { $OldVersion = $UpgradeListHash[$SoftwareName] }
		LogWrite "$($SoftwareName) was upgraded to version $($i) from version $($OldVersion)"
		$results = [pscustomobject]@{
				Computername = hostname
				Client	     = $ClientName
				UpgradedSoftware = $SoftwareName
				NewVersion   = $i
				OldVersion	     = $OldVersion
				Time = (get-date -Format MM-dd_HH:m:ss.ff)
			}
		function ResultToAzureTable
		{			
			$header = @{ 'Content-Type' = "application/json" }
			$flow = 'https://prod-126.westus.logic.azure.com:443/workflows/*' #URI for Power Automate Flow
			$flowheader = $results | ConvertTo-Json -Compress
			try
			{
				Invoke-RestMethod -Method Post -Body $flowheader -uri $flow -Headers $header -ErrorAction 'Stop'
				LogWrite "POST to Azure Table Successful!"
			}
			Catch
			{
				LogWrite "Error logging to Azure Table"; $global:RESTFailure = $true
			}
			Start-Sleep 2
		}
		ResultToAzureTable
		
		if ($RESTFailure){ResultToAzureTable} #Attempt to send REST POST to Azure table a second time		
		
	}
}

Get-Content $env:TEMP\$Log #Write Log to Console
#endregion Script

