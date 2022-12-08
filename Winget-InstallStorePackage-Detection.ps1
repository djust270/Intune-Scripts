$PackageID = '9WZDNCRFJB13' #Enter package ID here

# DO NOT MODIFY ANYTHING BELOW
# Leverage task scheduler to create a scheduled task as the logged on user
# Task will export all installed packages to file using Winget
winget export -o .\installedpackages.txt | out-null


$PackageList = ".\installedpackages.txt"
if (-Not (Test-Path $PackageList)){
    Write-Host "Wignet package list not found!"
    exit 1
}
$InstalledPackages = Get-Content $PackageList | ConvertFrom-Json
$IsInstalled = ($InstalledPackages).sources.packages | Where-Object {$_.packageidentifier -eq $PackageID}
if ($IsInstalled){
    Write-Host $PackageID " was detected!"
    remove-item $PackageList
    #exit 0
}
else {
    remove-item $PackageList
    #exit 1
}