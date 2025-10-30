#$DHCPServers = DHCP SERVER LIST 'abc3ds1','acb3ds2','abc3ds3'
# OR
#$DHCPServers = Get-DhcpServerInDC | Select-Object -ExpandProperty DnsName | Select-String '(^SELECT-DHCP-SERVER-STRING)'

$report = foreach ($server in $DHCPServers) {
    $bindings = Get-DhcpServerv4Binding -ComputerName $server
    if ($bindings) {
        $bindings | Select-Object @{Name='Server';Expression={$server}}, IPAddress, BindingState
    } else {
        [PSCustomObject]@{Server=$server; IPAddress=$null; BindingState='No bindings found'}
    }
}

$report