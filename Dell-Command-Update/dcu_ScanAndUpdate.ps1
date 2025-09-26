#+-------------------------------------------------------------+  
#| Author:  Jeremy Rousseau
#| Purpose: Set Dell Command Update to Manual then then run scan and update
#| Version: 1.0
#+--------------------------------------------------------------

#+-------------------------------------------------------------+  
#| Change Log:
#| Version 1.0 - Initial script
#+-------------------------------------------------------------+

# Set DCU paths
$possiblePaths =
  "$env:ProgramFiles\Dell\CommandUpdate\dcu-cli.exe",
  "${env:ProgramFiles(x86)}\Dell\CommandUpdate\dcu-cli.exe"

# Set correct DCU path
$correctPath = foreach( $path in $possiblePaths ) {
  if( Test-Path -PathType Leaf $path ) {
    $path
    break
  }
}

# Throw error if DCU not available
if( !$correctPath ) {
  throw "Could not find dcu-cli.exe at any of the following paths: $(@( $possiblePaths ) -join ', ')"
}

# Set logging
$DCU_ConfigReport='C:\tmp\dcuConfig.log'
$DCU_ScanReport='C:\tmp\dcuScan.log'
$DCU_ApplyReport='C:\tmp\dcuApply.log'

# Set DCU to manual and allow reboot deferral
Start-Process $correctPath -ArgumentList "/configure -scheduleManual -updatesNotification=enable -systemRestartDeferral=enable -deferralRestartInterval=1 -deferralRestartCount=2 -outputLog=$DCU_ConfigReport -silent" -NoNewWindow -wait

# Start DCU Scan
Start-Process $correctPath -ArgumentList "/scan -updateSeverity=security,critical,recommended -updateType=bios,firmware,driver,application -outputLog=$DCU_ScanReport -silent" -NoNewWindow -Wait

# Start DCU Update
Start-Process $correctPath -ArgumentList "/applyUpdates -updateSeverity=security,critical,recommended -updateType=bios,firmware,driver,application -reboot=enable -autoSuspendBitLocker=enable -forceUpdate=enable -outputLog=$DCU_ApplyReport -silent" -NoNewWindow -Wait
