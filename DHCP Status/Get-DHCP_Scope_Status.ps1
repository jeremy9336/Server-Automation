$dhcpServer = Get-DhcpServerInDC | Select-Object -ExpandProperty DnsName | Select-String '(^SELECT-DHCP-SERVER-STRING)'
	foreach ($server in $dhcpServer) {
		Get-DhcpServerv4Scope -ComputerName "$server" | select ScopeId,Name,State | Where-Object State -li "Inactive" | FT -auto
		}