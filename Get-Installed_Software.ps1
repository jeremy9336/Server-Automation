#+-------------------------------------------------------------+  
#| Author:  Jeremy Rousseau
#| Purpose: Get list of installed software from servers
#| Version: 1.0
#+--------------------------------------------------------------

#+-------------------------------------------------------------+  
#| Change Log:
#| Version 1.0 - Initial script
#+-------------------------------------------------------------+

$servers = get-content c:\tmp\servers.txt

$report = @()

ForEach ($server in $servers)
{
write-host checking $server

# MUST USE ONE OF THESE OPTIONS 
# OPTION 1 - Look for software like name
# $check = Get-WmiObject -Class Win32_Product | where name -li *bigfix* | select Name,Version | Select -Last 1

# OPTION 2 - No filtering
$check = Get-WmiObject -Class Win32_Product | select Name,Version | Select -Last 1

$obj = New-Object psobject;
$obj | add-member -type NoteProperty -name Server -value $server;
$obj | add-member -type NoteProperty -name SoftwareName -value $check.name;
$obj | add-member -type NoteProperty -name Version -value $check.version;
$report += $obj;
}

$report | Export-Csv -Path c:\tmp\software_report.csv -NoTypeInformation -Force