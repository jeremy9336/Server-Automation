<#
.SYNOPSIS
	The script sets IP ranges for HBFWs.

.DESCRIPTION
	Script summarry: Import modules, import GPOs, configure GPOs
	Parameters not accepted.
	NOTE: This script can take a few minutes to complete.

.NOTES
	AUTHOR
	Jeremy Rousseau

	DATE 01/31/2024
	VERSION 1.1

.INPUTS
	None

.OUTPUTS
	None

.LINK
	None

.EXAMPLE
	PS> Update-HBFW_IP.ps1
#>

# Set params
#
# GPOs to be configured
$file = import-csv -Delimiter "," 'C:\tmp\Scripts\HBFW\HBFW-GPO_Report_DATE.csv'

# Import PS module(s)
import-module grouppolicy

# Import GPOs to be configured
foreach ($line in $file) {
 
    # Set new IPs if Remote Address is not NULL
    If (-not [string]::IsNullOrWhiteSpace($line.'Remote Address') )
    {
    # build vars
    # "GPName","RuleName","Remote Address"
    $Domain = "abc.net\"
    $GPO = $($line.GPName)
    $GpoName = $Domain+$GPO
    $FwRule = $($line.RuleName)
    
    # Build currrent Ip array
    $OldIps=$line.'Remote Address'
    $Ips=""
    foreach($OldIp in $OldIps){

        $Ips=("$OldIp"+", ").ToString()
        $counter++
        }
    
    # Set NEW Ips
    $NewIps = @("207.182.34.0/23,208.91.112.0/21,203.113.44.0/24,202.88.192.0/20,207.155.90.0/23")
    #$NewIps = @(",3.3.3.3")
    #$NewIps = @(",1.1.1.0-1.1.1.25")
    #$NewIps = @(",4.4.0.0/12")
    
    # Combine Old and New Ips
    $AllIps= ("$NewIps").ToString()
        
    # set IPs
    $GpoSessionName = Open-NetGPO –PolicyStore $GpoName
    Set-NetFirewallRule –DisplayName $FwRule –GPOSession $GpoSessionName -RemoteAddress $AllIps.Split(",",$counter) -PassThru
    Save-NetGPO -GPOSession $GpoSessionName
    }
}