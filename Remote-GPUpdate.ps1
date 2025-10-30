#+-------------------------------------------------------------  
#| Purpose: Perform a Remote GPUpdate
#| Author:  Jeremy Rousseau
#| Date: 07-19-2022
#| Version: 1.0
#+-------------------------------------------------------------

#+-------------------------------------------------------------  
#| Change Log:												   
#| Version 1.0 - Initial build                                 
#+------------------------------------------------------------- 

### DO 	NOT EDIT BELOW THIS LINE ###

# Set parameters
param ([Parameter(Position=0)]$HostName)

if ($HostName -eq $null) { # If param is empty, prompt user for input
# Get Server  
$HostName = Read-Host -Prompt 'Enter Hostname(example: abc3ap1)'
if ($HostName) {
	Write-Host ""
} else {
	Write-Warning -Message "No hostname input, exiting..."
    pause
    exit
}
}

Invoke-Command -ComputerName $HostName -ScriptBlock { "Invoke-GPUpdate -RandomDelayInMinutes 0 -Force -Boot" }
