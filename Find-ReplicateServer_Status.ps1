#+-------------------------------------------------------------  
#| Purpose: Will show the last replication time of a computer object on each DC in the domain
#|			Works great to show the replication status of a new DC when 
#| Author:  Jeremy Rousseau
#| Date: 09-13-2023
#| Version: 1.0
#+-------------------------------------------------------------

#+-------------------------------------------------------------  
#| Change Log:												   
#| Version 1.0 - Initial build                                 
#+------------------------------------------------------------- 

#Change value for $ComputerName as needed
$ComputerName = "abc3ap2"

### DO 	NOT EDIT BELOW THIS LINE ###

$var="*"
$Computer="$Computername$var"

$TargetDomain = Get-AdDomain | Select Name,DNSRoot,NetBIOSName,DomainMode,PDCEmulator
$RwDcs = @()

$RwDcs = Get-ADDomainController -Filter {IsReadOnly -eq $false} -Server $TargetDomain.PDCEmulator

ForEach ($DC in $RwDcs)
 {
 get-adcomputer -filter 'name -like $computer' -Server $DC.hostname -properties whenchanged,msDS-AdditionalDnsHostName |ft $DC.hostname,name,whenchanged,msDS-AdditionalDnsHostName
}
