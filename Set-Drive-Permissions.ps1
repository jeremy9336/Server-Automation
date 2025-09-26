#+-------------------------------------------------------------+  
#| Author:  Jeremy Rousseau
#| Purpose: Set Drive Permissions
#| Version: 1.0
#+--------------------------------------------------------------

#+-------------------------------------------------------------+  
#| Change Log:
#| Version 1.0 - Initial script
#+-------------------------------------------------------------+

$acl = (Get-Item c:\).GetAccessControl("Access")
$acl|format-list
$accessrule1 = New-Object system.security.AccessControl.FileSystemAccessRule("Everyone","ReadAndExecute",,,"Allow")
$accessrule2 = New-Object system.security.AccessControl.FileSystemAccessRule("CREATOR OWNER","FullControl",,,"Allow")
$accessrule3 = New-Object system.security.AccessControl.FileSystemAccessRule("BUILTIN\Users","CreateFiles","ContainerInherit","InheritOnly","Allow")
$accessrule4 = New-Object system.security.AccessControl.FileSystemAccessRule("BUILTIN\Users","AppendData","ContainerInherit","None","Allow")
$acl.RemoveAccessRuleAll($accessrule1)
$acl.RemoveAccessRuleAll($accessrule2)
$acl.RemoveAccessRuleSpecific($accessrule3)
$acl.RemoveAccessRuleSpecific($accessrule4)
$acl|format-list

gwmi win32_volume -Filter 'drivetype = 3' | ForEach-Object {
	$currentDrv = $_.driveletter + "\"
	If($currentDrv -ne "\") {
	set-acl -Path $currentDrv -aclobject $acl 
	echo $currentDrv
	}
}

