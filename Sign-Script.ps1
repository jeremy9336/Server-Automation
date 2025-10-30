<#
.SYNOPSIS
Digially Sign PowerShell Scripts

.DESCRIPTION
This PowerShell script will prompt user for PS file location and name, then digitally sign script.

.INPUTS
User Prompted

.OUTPUTS
Digitally Signed Script in orginal location

.EXAMPLE
c:\>.\Sign-Script.ps1
Execute script from a PowerShell command line(Run as regular user)

.NOTES
Author:  Jeremy Rousseau

Version: 1.0
Date: 06/07/2018

Change Log
Version 1.0 Initial release

NOTES:
Signing Powershell scripts with Powershell using a code signing certificate granted by a Certificate Authority.
1.	Getting a code signing certificate
2.	Pre-Requisite: This requires membership in the XX.XX.XX AD group
1.	Open the MMC console as your normal user account
2.	File Menu > Add/Remove Snap-in
3.	Select Certificates > Add (Current User)
4.	Click OK
5.	Expand until Personal>Certificates is selected
6.	Right click Certificates>All Tasks> Select Request New Certificate
7.	In the “Before You Begin” window, Click on Next
8.	In the “Select Certificate Enrollment Policy” windows, Click on Next
9.	In the “Request Certificates” window, check the box next to SCUPCode Signing. Click Enroll.
10.	Wait until the status bar shows “Succeeded”
11.	Click Finish
12.	You should now have a new certificate that shows “Intended Purpose” as Code Signing
13.	You should export this certificate to your “My Docs” directory so that you have a backup and can re-install if needed.
3.	Signing Powershell Scripts (These two lines should be ran separately, run the first, then the second) or all can be ran together as part of a PS1 script when the scripts path\name to be signed is included:
1.	Open Powershell with your normal user account
2.	CD to the location of the script file to be signed
3.	Run: $cert=(dir cert:currentuser\my\ -codesigningcert)
4.	Run: Set-AuthenticodeSignature .\<scriptname.ps1> $cert -IncludeChain "All" -TimestampServer http://timestamp.verisign.com/scripts/timstamp.dll
Notes:
If you have two code signing certificates, they will interfere with each other. Keep only the latest issued certificate and delete any that were issued previously.
The –TimeStampServer option is required if you require the certificate to be validated past the time of the certificate expiration date.

.LINK
None
#>
# Prompt user for script location and name, PS files only
Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    #OpenFileDialog.filter = "PS (*.ps*)| *.ps*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

Write-Host -ForegroundColor Red "SCRIPT MUST BE RAN AS REGULAR USER"

# Run function Get-FileName
[String]$FileToSign = Get-FileName

# Get signing certificate
$cert=(dir cert:currentuser\my\ -codesigningcert)

# Sign script
Set-AuthenticodeSignature $FileToSign $cert -IncludeChain "All" -TimestampServer http://timestamp.verisign.com/scripts/timstamp.dll

Write-Host -ForegroundColor Green "Your script has been signed"