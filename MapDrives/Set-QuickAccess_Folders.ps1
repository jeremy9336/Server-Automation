#+-------------------------------------------------------------  
#| Purpose: Set Quick Access Folders
#| Author:  Jeremy Rousseau
#| Date: 07/19/2022
#| Version: 1.0
#+-------------------------------------------------------------

#+-------------------------------------------------------------  
#| Change Log:												   
#| Version 1.0 - Initial build                                 
#+------------------------------------------------------------- 

$folder1 = "\\abc.net\dfs\ny\loc1"
$folder2 = "\\abc.net\dfs\dc\loc2"
$folder3 = "\\abc.net\dfs\fl\loc3"

### DO 	NOT EDIT BELOW THIS LINE ###

$folders = $folder1,$folder2,$folder3

foreach ($folder in $folders)
    {
    #Pin to Quick Access
    $QuickAccess = New-Object -ComObject shell.application
    $QuickAccess.Namespace($folder).Self.InvokeVerb("pintohome")
    }