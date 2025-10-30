<#
.SYNOPSIS
	The script is to send Host-Based Firewalls status emails.

.DESCRIPTION
	Script summarry: Import AD Module, query AD for servers that are not a member of abcAllfwServers, send results as email.
	Parameters not accepted.

.NOTES
	AUTHOR
	Jeremy Rousseau

	DATE 07/02/2021
	VERSION 1.0

.INPUTS
	None

.OUTPUTS
	Email

.LINK
	None

.EXAMPLE
	PS> Send-HBFW_Status_Email.ps1
#>

#Send script to help if parameters are defined
if($args.Count -gt 0) {
    Get-Help $MyInvocation.MyCommand.Definition
    return
}

#Load AD Module for PowerShell
import-module ActiveDirectory

#Set variables
$from = 'Fed <fred@abc.net>'
$to = 'Server Admins <SA@abc.net>'
$subject = ($date = Get-Date -Format "MM/dd/yyyy") + (" Servers Not Configured for HBFW")
$smtpServer = 'smtp.abc.net'

#Query AD and set as body of email
$body = (Get-ADComputer -Filter 'operatingsystem -like "*server*" -and primarygroupid -ne "516"' -Property memberof,name | Where-Object {[string]$_.MemberOf -notlike "*abcAllfwServers*" } | Select-Object name | Sort-Object name | Format-Table -AutoSize -OutVariable message | Out-String)

#Format email
$email = @{
From = $from
To = $to
Subject = $subject
SMTPServer = $smtpServer
Body = $body
}

#Send email
Send-MailMessage @email