# *****************************************************************
# * Install-RSATv2.ps1
# *****************************************************************
# Description:
# This script installs RSAT
# *****************************************************************
# * Version: 2.0
# *
# * Original Author:  Jeremy Rousseau
# *****************************************************************
# * Version * Date      * Changes
# *****************************************************************
# * 2.0     * 07/17/24  * Jeremy Rousseau - Script Rebuild

# >>>>> DO NOT MODIFY CODE BELOW THIS LINE <<<<<

# Menu function
Function Show-Menu
{
    Clear-Host
    Write-Host "This script must be run with elevated permissions(Admin)"
    Write-Host "Press 1 : Yes, I'm running as admin"
    Write-Host "Press 2 : No, I'm not running as admin"
    Write-Host "Press Q to quit."
}

# RSAT Install function
Function Install-RSAT {

#Check for running as admin
$CheckforAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

If($CheckforAdmin -eq $false){
	write-host "Not running as admin. Script exit." -ForegroundColor Red
    write-host "Start PowerShell as Admin and run script again." -ForegroundColor Red
    Exit
}

#List installed RSAT components
Write-Host "Currently installed RSAT(if any):" -ForegroundColor Yellow
Get-WindowsCapability -Name RSAT* -Online | Select-Object -Property Name, State

#Set Update Service Locations: Internet
Write-Host "RSAT Install: Setting Windows update locations to Microsoft Windows Update" -ForegroundColor Yellow
$UseWUServer = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" | Select-Object -ExpandProperty UseWUServer
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name DisableWindowsUpdateAccess -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name SetPolicyDrivenUpdateSourceForDriverUpdates -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name SetPolicyDrivenUpdateSourceForFeatureUpdates -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name SetPolicyDrivenUpdateSourceForOtherUpdates -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name SetPolicyDrivenUpdateSourceForQualityUpdates -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name UseUpdateClassPolicySource  -Value 0

#Clear Cache
Write-Host "RSAT Install: Clearing Windows Update CACHE" -ForegroundColor Yellow
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache\CacheSet001\WindowsUpdate" -Recurse -Force
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache\CacheSet002\WindowsUpdate" -Recurse -Force
New-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache\CacheSet001\WindowsUpdate"
New-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache\CacheSet001\WindowsUpdate\AU"
New-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache\CacheSet002\WindowsUpdate"
New-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\GPCache\CacheSet002\WindowsUpdate\AU"

#Restart Windows Update Service
Write-Host "RSAT Install: Restarting Windows Update Service" -ForegroundColor Yellow
Restart-Service "Windows Update"

#Get RSAT Online
Write-Host "RSAT Install: Installing RSAT" -ForegroundColor Yellow
Write-Host "RSAT Install: This will take a few minutes..." -ForegroundColor Yellow
Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online
Write-Host "RSAT Install: Install complete" -ForegroundColor Green

#Set Update Service Locations: WSUS
Write-Host "RSAT Install Clean-up: Setting Windows update locations back to WSUS" -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value $UseWUServer
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "SetPolicyDrivenUpdateSourceForDriverUpdates" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "SetPolicyDrivenUpdateSourceForFeatureUpdates" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "SetPolicyDrivenUpdateSourceForOtherUpdates" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "SetPolicyDrivenUpdateSourceForQualityUpdates" -Value 1

#Restart Windows Update Service
Write-Host "RSAT Install Clean-up: Restarting Windows Update Service" -ForegroundColor Yellow
Restart-Service "Windows Update"

#List installed RSAT components
Write-Host "RSAT installed:" -ForegroundColor Yellow
Get-WindowsCapability -Name RSAT* -Online | Select-Object -Property Name, State
	
# END Function Install-RSAT
}

#Do something
do
{
    Show-Menu
    $input = Read-Host "Make a selection from the list"
    switch ($input)
    {
        '1' {               
                Install-RSAT
            }
        '2' {
                write-host "Not running as admin. Script exit." -ForegroundColor Red
                write-host "Start PowerShell as Admin and run script again." -ForegroundColor Red
                Exit
            }
        'q' {
                return
            }
    }
    pause
}
until ($input -eq 'q')
