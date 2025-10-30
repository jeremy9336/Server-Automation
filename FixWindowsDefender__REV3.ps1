<#
.SYNOPSIS
	The script is to fix Windows Defender issues

.DESCRIPTION
	Correct issues with Windows Defender's configuration and start

.NOTES
	AUTHOR
	Jeremy Rousseau

	DATE 01/22/2021
	VERSION 3.1

.OUTPUTS
	Log file = c:\SoftwareLogs\FixWindowsDefenderReport.txt
	
.LINK
	None

.EXAMPLE
	PS> FixWindowsDefender.ps1

#>

# Set logging 
$log = "c:\SoftwareLogs\FixWindowsDefenderReport.txt"
# Current Platform version
$platform = "4.18.2011.6-0"
# Source folder location 
$Source = "\\abc\dfs\rep\ent\sys\msi\Microsoft\DefenderATP\$platform"
# Dest folder location
$platformFolder = "C:\ProgramData\Microsoft\Windows Defender\Platform\$platform"

function Takeown-Registry($key) {
    # TODO does not work for all root keys yet
    switch ($key.split('\')[0]) {
        "HKEY_CLASSES_ROOT" {
            $reg = [Microsoft.Win32.Registry]::ClassesRoot
            $key = $key.substring(18)
        }
        "HKEY_CURRENT_USER" {
            $reg = [Microsoft.Win32.Registry]::CurrentUser
            $key = $key.substring(18)
        }
        "HKEY_LOCAL_MACHINE" {
            $reg = [Microsoft.Win32.Registry]::LocalMachine
            $key = $key.substring(19)
        }
    }

    # get administraor group
    $admins = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    $admins = $admins.Translate([System.Security.Principal.NTAccount])

    # set owner
    $key = $reg.OpenSubKey($key, "ReadWriteSubTree", "TakeOwnership")
    $acl = $key.GetAccessControl()
    $acl.SetOwner($admins)
    $key.SetAccessControl($acl)

    # set FullControl
    $acl = $key.GetAccessControl()
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule($admins, "FullControl", "Allow")
    $acl.SetAccessRule($rule)
    $key.SetAccessControl($acl)
}

function Elevate-Privileges {
    param($Privilege)
    $Definition = @"
    using System;
    using System.Runtime.InteropServices;

    public class AdjPriv {
        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
            internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr rele);

        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
            internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);

        [DllImport("advapi32.dll", SetLastError = true)]
            internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);

        [StructLayout(LayoutKind.Sequential, Pack = 1)]
            internal struct TokPriv1Luid {
                public int Count;
                public long Luid;
                public int Attr;
            }

        internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
        internal const int TOKEN_QUERY = 0x00000008;
        internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;

        public static bool EnablePrivilege(long processHandle, string privilege) {
            bool retVal;
            TokPriv1Luid tp;
            IntPtr hproc = new IntPtr(processHandle);
            IntPtr htok = IntPtr.Zero;
            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
            tp.Count = 1;
            tp.Luid = 0;
            tp.Attr = SE_PRIVILEGE_ENABLED;
            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
            return retVal;
        }
    }
"@
    $ProcessHandle = (Get-Process -id $pid).Handle
    $type = Add-Type $definition -PassThru
    $type[0]::EnablePrivilege($processHandle, $Privilege)
}

function Set-RegistryValue {
	param(
		[string]$Path,
		[string]$Name,
		[string]$Value
	)

	# Set value
	Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force

	# Check and report
	If (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) {
		"$Path\$Name set to $Value" | Out-File -FilePath $log -Append
	} Else {
		"Error setting $Path\$Name to $Value" | Out-File -FilePath $log -Append
	} 
}

function Remove-RegistryValue {
	param(
		[string]$Path,
		[string]$Name
	)
	
	# Check value first
	If (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) {
		# Force remove if exists
		Remove-ItemProperty -Path $Path -Name $Name -Force
		# Report removal
		"$Path\$Name removed" | Out-File -FilePath $log -Append
	} Else {
		# Report not present
		"$Path\$Name did not exist" | Out-File -FilePath $log -Append
	} 
}

## Copy Platform files
# If platform folder is not already present
if (-not(Test-Path $platformFolder)) {
	# Ensure source folder if present
	if (Test-Path $Source) { 
		# Copy to location
		Copy-Item $Source $platformFolder -Recurse -Force | Out-Null
		# Report copied
		"$platformFolder copied." | Out-File -FilePath $log -Append
	# End script if source is not present
	} else { throw "$Source folder not present to copy!" }
# Report not copied
} else { "$platformFolder already present." | Out-File -FilePath $log -Append }

## Disable RealtimeMonitoring if present
try { 
	Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
	"RealtimeMonitoring disabled" | Out-File -FilePath $log -Append
} catch { 
	"RealtimeMonitoring not present" | Out-File -FilePath $log -Append
}

## Take ownership of registry keys
do {} until (Elevate-Privileges SeTakeOwnershipPrivilege)
Takeown-Registry("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WinDefend")
Takeown-Registry("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender")

## Set Defender enabled + passive
#1 DisableAntiSpyware, value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 0
#2 DisableAntiVirus, value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender" -Name "DisableAntiVirus" -Value 0
#3 PassiveMode, value 2
Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender" -Name "PassiveMode" -Value 2
#4 ForceDefenderPassiveMode, value 1
Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection" -Name "ForceDefenderPassiveMode" -Value 1
#5 ForceDefenderPassiveMode, value 1
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection" -Name "ForceDefenderPassiveMode" -Value 1

### Remove Defender disabled policies if present
#1 DisableAntiVirus, remove
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiVirus"
#2 DisableAntiSpyware, remove
Remove-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware"

### Modify services to reflect new platform location
#1 WinDefend DisplayName
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Name "DisplayName" -Value "@%ProgramFiles%\Windows Defender\MpAsDesc.dll,-310"
#2 WinDefend ImagePath
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Name "ImagePath" -Value "%ProgramData%\Microsoft\Windows Defender\platform\4.18.2011.6-0\MsMpEng.exe"
#3 WinDefend Start
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Name "Start" -Value 2
#4 NIS ImagePath
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WdNisSvc" -Name "ImagePath" -Value "%ProgramData%\Microsoft\Windows Defender\platform\4.18.2011.6-0\NisSrv.exe"
#5 Sense Start
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Sense" -Name "Start" -Value 2
#6 Set sc autostart (for redundancy)
sc.exe config WinDefend start= auto | Out-Null
sc.exe config Sense start= auto | Out-Null


