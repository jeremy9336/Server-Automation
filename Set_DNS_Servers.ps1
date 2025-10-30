# *****************************************************************
# * Set_DNS_Servers.ps1
# *****************************************************************
# Description:
# Set DNS setting when connected to VPN
# *****************************************************************
# * Version: 1.0
# *
# * Original Author:  Jeremy Rousseau
# *****************************************************************
# * Version * Date      * Changes
# *****************************************************************
# * 1.0     * 02/08/24  * Jeremy Rousseau - Initial release
#
# NOTES:
# 1) Run as scheduled task based on time or event
#
# 2) Must match when a process/service that starts after VPN, such as VPN process = $Get_Srvs = "VPN SERVICE NAME ???"

##### DO NOT MODIFY CODE BELOW THIS LINE #####

# Delay for VPN to fully connect
Start-Sleep -Seconds 10

# Get computers TimeZone
$TimeZone = (Get-TimeZone).id

# Set variable for DNS based on TimeZone
switch -Wildcard ( $TimeZone ) 
{
'*Atlantic*'   {$DNS_ip = @("SET DNS IP")}
'*Eastern*'    {$DNS_ip = @("SET DNS IP")}
'*Central*'    {$DNS_ip = @("SET DNS IP")}
'*Mountain*'   {$DNS_ip = @("SET DNS IP")}
'*Pacific*'    {$DNS_ip = @("SET DNS IP")}
'*Alaska*'     {$DNS_ip = @("SET DNS IP")}
'*UTC*'        {$DNS_ip = @("SET DNS IP")}
default        {$DNS_ip = @("SET DNS IP")}
}

# Debug / Write-host TimeZone and DNS_IP variables
$timezone
$dns_ip

# Write DNS ips to GP adapter
$Get_Srvs = Get-NetAdapter -IncludeHidden | where-object InterfaceDescription -Match "VPN SERVICE NAME ???"
set-dnsclientserveraddress -InterfaceIndex $Get_Srvc.ifIndex -ServerAddresses $DNS_ip

#Dynamic DNS register to ADDNS
Register-DnsClient