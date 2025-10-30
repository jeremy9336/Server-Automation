<#
.SYNOPSIS
	The script is to deploy Host-Based Firewalls to Servers.

.DESCRIPTION
	Script summarry: Import AD Module, backup the current firewall, add hostname to security groups, GPO Udate on server, Create 'HBFW_SystemReboot' task to reboot server, Create 'HBFW_ClearFirewalls' task to clear default firewall rules, and set logging.

.NOTES
	AUTHOR
	Jeremy Rousseau

	DATE 04/28/2021
	VERSION 1.3

.PARAMETER server
	Specify the server hostname

.INPUTS
	Server hostname on commandline
	or
	Hostname file located at C:\tmp\HBFW_Servers.txt

.OUTPUTS
	Log file = c:\tmp\fwLog_$server.txt

.LINK
	None

.EXAMPLE
	PS> Set-HBFW_Servers.ps1 -servers abc3ap1

.EXAMPLE
	PS> Set-HBFW_Servers.ps1 -servers abc3ap1, abc3ap2

.EXAMPLE
	PS> Set-HBFW_Servers.ps1
	## Starts menu
	=================================================
	  Press '1' to Be prompted for hostname
	  Press '2' to Run script using a hostname file
	  Press '3' to Display HBFW AD Groups
	  Press 'Q' to quit.
	=================================================
	Select a menu item:
#>

# ENTRY POINT MAIN()
Param(
	[Parameter(
		ValueFromPipeline=$true,
		Position=0)]
		$servers
	)

Clear-Host
# Set server parameter
if ([string]::IsNullOrWhiteSpace($servers)) {
	Write-Host "================================================="
	Write-Host "  Press '1' to Be prompted for hostname"
	Write-Host "  Press '2' to Run script using a hostname file"
	Write-Host "  Press '3' to Display HBFW AD Groups"
	Write-Host "  Press 'Q' to quit."
	Write-Host "================================================="

switch(Read-Host "Select a menu item") {
    1 {
        $servers = Read-Host -Prompt 'Enter Hostname(example: abc3ap1)'
		} 
    2 {
		Write-Warning -Message "Script will run same action on each server"
		$servers = Get-Content -path C:\tmp\HBFW_Servers.txt
		}
	3 {
		Write-Host ""
		Write-Host "AD Groups and server functions." -ForegroundColor DarkCyan
		Write-Host ""
		$fwGroups = Get-ADGroup -Filter { name -like "abcGfw*" } -Properties name,description
			foreach($fwGroup in $fwGroups)
			{ 
			Write-Host "$($fwGroup.name)" - "$($fwGroup.Description)"
			}
		Write-Host ""
		exit
		}
	q { exit }
    default {Write-Warning -Message "Invalid selection, exiting..."; exit}
	}
}

# Test for server connection
$Noping = @()
$pingable = @()
foreach ($c in $servers) {
    write-Host "Attempting to ping - $c" -ForegroundColor Green
    if (test-Connection -ComputerName $c -Count 1 -Quiet) 
        {             
        $pingable += $c
        }
          
        else
        {
        $NoPing += $c
        Write-Warning -Message "Unable to ping $c" 
        }
    }

# Create log for servers failed connection 
$NoPing | Out-File -FilePath c:\tmp\noPing.txt -Append
if ($NoPing) { Write-Host "No PING file create: c:\tmp\noPing.txt" }

# If no pingable servers then throw messaged and exit
if (!$pingable) {
	Write-Warning -Message "No servers online, exiting..."
	exit;
}

Start-sleep -seconds 2

#Load AD Module for PowerShell
import-module ActiveDirectory

# Set time parameters
if ([string]::IsNullOrWhiteSpace($rebootTime)) {
$rebootTime = Read-Host -Prompt 'Enter Reboot Time(example: 19:00)';
$clearRulesTime = (get-date $rebootTime).AddMinutes(5).ToString("HH:mm")
}

Write-Host "Make selection from the pop-up dialog box." -ForegroundColor DarkCyan
Start-sleep -seconds 2

##### START SELECT BOX #####
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select Group(s)'
$form.Size = New-Object System.Drawing.Size(265,360)
$form.StartPosition = 'CenterScreen'

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(50,280)
$OKButton.Size = New-Object System.Drawing.Size(65,23)
$OKButton.Text = 'OK'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(125,280)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(225,50)
$label.Text = 'Please make a selection from the list below. All servers should have at a minimum abcGfwAllServers. Make multiple selections using CTRL and selecting objects.'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.Listbox
$listBox.Location = New-Object System.Drawing.Point(10,70)
$listBox.Size = New-Object System.Drawing.Size(220,20)

$listBox.SelectionMode = 'MultiExtended'

$fwGroups = Get-ADGroup -Filter { name -like "abcGfw*" } -Properties name
foreach($fwGroup in $fwGroups)
{ 
    [void]$listBox.items.add($($fwGroup.name))
}

$listBox.Height = 200
$form.Controls.Add($listBox)
$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
		$groups = $listBox.SelectedItems
	}

if ($groups) {
		Write-Host ""
	} else {
		Write-Warning -Message "No group(s) selected, exiting..."
		exit
		}

##### END SELECT BOX #####

# Create function: backup the current firewall
function BackupFirewall {
	# Test for C:\Loc\Sys and create if not found
    $logPath = "C:\Loc\Sys"
	if ( $(Try { Test-Path $logPath.trim() } Catch { $false }) ) {
		# Do nothing if true
		}
	Else {
		write-host "Backup directory not found, creating."
		New-Item -Path $logPath -ItemType Directory
		}
	
	$date = get-date -format "dd-MMM-yyyy_HHmm"
    $name = "$logPath\fw-rules-$date.wfw"
	$command0 = { netsh advfirewall export $Using:name }
    Invoke-Command -ComputerName $server -ScriptBlock $command0
    } # END FUNCTION

# Create Function: add hostname to security groups
function AddSecurityGroups {
    foreach ( $group in $groups ) {
        Add-ADGroupMember $group -members "$server$"
        }
    } # END FUNCTION

# Create function: GPUdate on server
function GPOUpdate {
    Invoke-GPUpdate -Computer $server -Target "Computer"
    } # END FUNCTION

# Create function: Create 'HBFW_SystemReboot' task to reboot server at 19:00 LOCAL
function ScheduleReboot {
	Invoke-Command -ComputerName $server -ScriptBlock { schtasks /CREATE /RL highest /SC once /TN HBFW_SystemReboot /TR "shutdown.exe /r /t 30 /c 'Firewall Reboot' /d p:4:1" /ST $Using:rebootTime -RU "SYSTEM" }
	} # END FUNCTION
	
# Create function: Create 'HBFW_ClearFirewalls' task to reboot server at 19:15 LOCAL 
function ScheduleClearFirewalls {
    Invoke-Command -ComputerName $server -ScriptBlock { schtasks /CREATE /RL highest /SC once /TN HBFW_ClearFirewalls /TR "powershell -command Remove-NetFirewallRule" /ST $Using:clearRulesTime -RU "SYSTEM" }
    } # END FUNCTION

# Start HBFW Deployment
foreach ($server in $pingable) {
Write-Host "Setting up HBFW parameters for $server" -ForegroundColor DarkCyan

# Set logging name, date, and RunAs User 
$log = "c:\tmp\fwLog_$server.txt"
$logDate_start = get-date -format "dd-MMM-yyyy HH:mm:ss"
$User = $(whoami)

#Start script and logging
$User | Out-File -FilePath $log -Append 
$server | Out-File -FilePath $log -Append 
$logDate_start | Out-File -FilePath $log -Append 
"Start HBFW deployment" | Out-File -FilePath $log -Append
Write-Host ""
Write-Host "##### Deploying HBFW to $server #####" -ForegroundColor DarkCyan

# Run function: Backup current firewall settings to local server
"Backing up firewall" | Out-File -FilePath $log -Append
Write-Host "Backing up firewall. Location: c:\loc\sys"
BackupFirewall | Out-File $log -Append

# Run function: Add security groups to enable firewall and rules
"Adding security groups" | Out-File -FilePath $log -Append
$groups | Out-File -FilePath $log -Append
Write-Host "Adding security groups:"
Write-Host "===================="
$groups
Write-Host "===================="
AddSecurityGroups | Out-File $log -Append

# Run function: GPUdate on server
"Running GPUpdate" | Out-File -FilePath $log -Append
Write-Host "Running GPUpdate"
GPOUpdate | Out-File $log -Append

# Run function: schedule reboot
"Scheduling reboot $rebootTime" | Out-File -FilePath $log -Append
Write-Host "Scheduling reboot $rebootTime"
ScheduleReboot | Out-File $log -Append

# Run function: schedule clear default firewalls
"Scheduling clearing firewalls $clearRulesTime" | Out-File -FilePath $log -Append
Write-Host "Scheduling clear firewalls $clearRulesTime"
ScheduleClearFirewalls | Out-File $log -Append

# HBFW Complete
"HBFW has been successfully deployed to $server" | Out-File -FilePath $log -Append
Write-Host ""
Write-Host "---> HBFW has been successfully deployed to $server" -ForegroundColor Green
Write-Host ""

# End Logging
"End HBFW deployment" | Out-File -FilePath $log -Append
$logDate_end = get-date -format "dd-MMM-yyyy HH:mm:ss"
$logDate_end | Out-File -FilePath $log -Append

}