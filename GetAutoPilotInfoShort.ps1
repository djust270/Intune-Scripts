$OutputFile = "C:\xpercare\$env:ComputerName.csv"
$session = New-CimSession
$devDetail = (Get-CimInstance -CimSession $session -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'")
if ($devDetail -and (-not $Force))
{
	$hash = $devDetail.DeviceHardwareData
}
else
{
	$bad = $true
	$hash = ""
}

# If the hash isn't available, get the make and model
if ($bad -or $Force)
{
	$cs = Get-CimInstance -CimSession $session -Class Win32_ComputerSystem
	$make = $cs.Manufacturer.Trim()
	$model = $cs.Model.Trim()
	if ($Partner)
	{
		$bad = $false
	}
}
else
{
	$make = ""
	$model = ""
}

# Getting the PKID is generally problematic for anyone other than OEMs, so let's skip it here
$product = ""

# Depending on the format requested, create the necessary object
if ($Partner)
{
	# Create a pipeline object
	$c = New-Object psobject -Property @{
		"Device Serial Number" = $serial
		"Windows Product ID" = $product
		"Hardware Hash" = $hash
		"Manufacturer name" = $make
		"Device model" = $model
	}
	# From spec:
	#	"Manufacturer Name" = $make
	#	"Device Name" = $model

}
else
{
	# Create a pipeline object
	$c = New-Object psobject -Property @{
		"Device Serial Number" = $serial
		"Windows Product ID" = $product
		"Hardware Hash" = $hash
	}
	
	if ($GroupTag -ne "")
	{
		Add-Member -InputObject $c -NotePropertyName "Group Tag" -NotePropertyValue $GroupTag
	}
	if ($AssignedUser -ne "")
	{
		Add-Member -InputObject $c -NotePropertyName "Assigned User" -NotePropertyValue $AssignedUser
	}
}

# Write the object to the pipeline or array
if ($bad)
{
	# Report an error when the hash isn't available
	Write-Error -Message "Unable to retrieve device hardware data (hash) from computer $comp" -Category DeviceError
}
elseif ($OutputFile -eq "")
{
	$c
}
else
{
	$computers += $c
	Write-Host "Gathered details for device with serial number: $serial"
}

Remove-CimSession $session
$computers | Select-Object "Device Serial Number", "Windows Product ID", "Hardware Hash" | ConvertTo-CSV -NoTypeInformation | ForEach-Object {$_ -replace '"',''} | Out-File $OutputFile
Write-Host "Autopilot info saved to C:\Xpercare\$($Env:Computername).csv"