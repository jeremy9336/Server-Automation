#+-------------------------------------------------------------  
#| Purpose: Test & compare PING times between 3 servers
#| Author:  Jeremy Rousseau
#| Date: 11-03-2023
#| Version: 1.0
#+-------------------------------------------------------------

#+-------------------------------------------------------------  
#| Change Log:												   
#| Version 1.0 - Initial build                                 
#+------------------------------------------------------------- 

# Edit server1 as the default known good server
Param(
	$interval = 300
	)
	$server1 = "abc2ap1"
	#$server2 = Read-Host -prompt "Input address for server 2"
	#$server3 = Read-Host -prompt "Input address for server 3"
	$loops = Read-Host -prompt "Input number of script loops"
cls
$i = $null
$d1Total = $null
$d2Total = $null
$d3Total = $null
#Write-Host -ForegroundColor White "$server1 is added by default"
Write-Host -ForegroundColor White "Script will loop through $loops times"
Write-Host -ForegroundColor Yellow -BackgroundColor DarkGray ("{0,-12}{1,9} {2,9} {3,9}" -f "Time","$server1","$server2","$server3")
Do{
	$d1 = Test-Connection $server1 -Count 1 -ErrorAction SilentlyContinue
	$d2 = Test-Connection $server2 -Count 1 -ErrorAction SilentlyContinue
	$d3 = Test-Connection $server3 -Count 1 -ErrorAction SilentlyContinue
	If($d1 -eq $null){$d1ResponseTime = 1000}Else{$d1ResponseTime = $d1.ResponseTime}
	If($d2 -eq $null){$d2ResponseTime = 1000}Else{$d2ResponseTime = $d2.ResponseTime}
	If($d3 -eq $null){$d3ResponseTime = 1000}Else{$d3ResponseTime = $d3.ResponseTime}
	$d1Total += $d1ResponseTime
	$d2Total += $d2ResponseTime
	$d3Total += $d3ResponseTime
	$i++
	$d1Avg = ($d1Total/$i)
	$d2Avg = ($d2Total/$i)
	$d3Avg = ($d3Total/$i)
	Write-Host -ForegroundColor White ("{0,-8:hh:mm:ss}" -f (Get-Date)) -NoNewline
	If($d1ResponseTime -ge ($d1Avg * 2)){
		Write-Host -ForegroundColor Red ("{0,10} ms" -f $d1ResponseTime) -NoNewline} Else{
		Write-Host -ForegroundColor White ("{0,10} ms" -f $d1ResponseTime) -NoNewline}
	If($d2ResponseTime -ge ($d2Avg * 2)){
		Write-Host -ForegroundColor Red ("{0,7} ms" -f $d2ResponseTime) -NoNewline} Else{
		Write-Host -ForegroundColor White ("{0,7} ms" -f $d2ResponseTime) -NoNewline}
	If($d3ResponseTime -ge ($d3Avg * 2)){
		Write-Host -ForegroundColor Red ("{0,8} ms" -f $d3ResponseTime)} Else{
		Write-Host -ForegroundColor White ("{0,8} ms" -f $d3ResponseTime)}
	Sleep $interval
}Until(
	$i -ge $loops
	)
