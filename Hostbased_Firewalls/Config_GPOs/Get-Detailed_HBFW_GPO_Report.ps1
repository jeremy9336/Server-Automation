<#
.SYNOPSIS
	The script is Get detailed report of HBFW GPOs.

.DESCRIPTION
	Script summarry: Import AD Module, query GPOs for detailed HBFW settings and save results as CSV file.
	Parameters not accepted.
	NOTE: This script can take a few minutes to complete.

.NOTES
	AUTHOR
	Jeremy Rousseau

	DATE 07/05/2021
	VERSION 1.1

.INPUTS
	None

.OUTPUTS
	c:\tmp\HBFW-GPO_Report[DATE].csv

.LINK
	None

.EXAMPLE
	PS> Get-Detailed_HBFW_GPO_Report.ps1
#>

#Send script to help if parameters are defined
if($args.Count -gt 0) {
    Get-Help $MyInvocation.MyCommand.Definition
    return
}

#Load AD Module for PowerShell
import-module ActiveDirectory

#Set date
$date = Get-Date -Format "MM-dd-yyyy"

#Get HBFW GPOs
$GPOs = Get-GPO -All | Where-Object {$_.displayname -like "NAME HBFW*"} | Select-Object DisplayName
foreach ($GPO in $GPOs ) {

#Get the GPO and store the results in an XML variable
[xml]$GpoXml = Get-GPOReport -Name $GPO.DisplayName -ReportType Xml

# Object with firewall fields
$PolicyDetails = foreach ($rule in $GpoXml.GPO.Computer.ExtensionData.Extension.InboundFirewallRules) {
    [PSCustomObject]@{
        "GPO" = $GPO.DisplayName
        "Rule Name" = $rule.Name
        "Profile" = ($rule.Profile) -join ','
        "Program" = $rule.App
        "Remote Address" = ($rule.RA4) -join ','
        "Protocol" = $rule.Protocol
        "Local Port" = ($rule.LPort) -join ',' 
    }
}

#Export the results
$PolicyDetails | Export-Csv -Path "c:\tmp\HBFW-GPO_Report_$date.csv" -NoTypeInformation -Append
}