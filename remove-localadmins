#simple script to remove any local admins not approved. Just change the names you are filtering by. Can be combined with a 
#scheduled task to run more than once

$admins = Get-LocalGroupMember administrators | where {$_.name -notmatch "dave" -and $_.name -notmatch "domain admins"} | select -ExpandProperty name 
$admins | foreach {Remove-LocalGroupMember -group "administrators" -member $_}
