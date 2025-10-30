#+-------------------------------------------------------------  
#| Purpose: Set Local Admin Group Membership
#| Author:  Jeremy Rousseau
#| Date: 12/11/2018
#| Version: 1.0
#+-------------------------------------------------------------

#+-------------------------------------------------------------  
#| Change Log:												   
#| Version 1.0 - Initial build                                 
#+------------------------------------------------------------- 

Function Global:Set-LocalAdminGroupMembership
{
    [CmdletBinding()]
    param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [string[]]$ComputerName,
    [Parameter(Position=1, Mandatory=$true)]
    [string[]]$Account
    )

    Process
    {  

        $Domain = $env:USERDNSDOMAIN

        if($Domain){
            $adsi = [ADSI]"WinNT://$ComputerName/administrators,group"
            $adsi.add("WinNT://$Domain/$Account,group")
            }else{
            Write-Host "Not connected to a domain." -foregroundcolor "red"
        }
    }# Process

}# 
#Set-LocalAdminGroupMembership -ComputerName abc3ap1 -Account ''
$Server = Read-Host -Prompt 'Input your server  name'

Set-LocalAdminGroupMembership -Account tsmith -ComputerName $Server