<#
.SYNOPSIS
Automates creation of a new Azure AD user, adds them to an HR group, and assigns RBAC roles.

.DESCRIPTION
This script uses Microsoft Graph PowerShell SDK to:
1. Create a new user
2. Add them to a designated Azure AD group
3. Assign RBAC roles
4. Log all operations and errors to a file

.REQUIREMENTS
Microsoft Graph PowerShell SDK: Install-Module Microsoft.Graph -Scope CurrentUser
Permissions: User.ReadWrite.All, Group.ReadWrite.All, RoleManagement.ReadWrite.Directory
Run as Global Administrator or Privileged Role Administrator

.AUTHOR
Jeremy Rousseau

Version: 1.0
Date: 06/10/2024

Change Log
Version 1.0 Initial release

#>

# ===========================
# Configuration Parameters
# ===========================
$DisplayName = "Terry Jones"
$UserPrincipalName = "tjones@abc.com"
$MailNickname = "tjones"
$Password = "Welcome@1234"
$GroupName = "HR_Users"
$RolesToAssign = @("HR Admin", "HR Manager")

# ===========================
# Logging Setup
# ===========================
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = "C:\tmp\Logs\HRUserCreation_$Timestamp.log"

# Create log directory if not exists
if (-not (Test-Path (Split-Path $LogFile))) {
    New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
}

# Function to log messages with timestamps
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Time] [$Level] $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogFile -Value $LogMessage
}

# ===========================
# Connect to Microsoft Graph
# ===========================
try {
    Write-Log "Connecting to Microsoft Graph..."
    Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "RoleManagement.ReadWrite.Directory" -ErrorAction Stop
    Write-Log "Connected to Microsoft Graph successfully."
}
catch {
    Write-Log "Failed to connect to Microsoft Graph. Error: $($_.Exception.Message)" "ERROR"
    exit 1
}

# ===========================
# Step 1: Create User
# ===========================
try {
    Write-Log "Creating user: $DisplayName ($UserPrincipalName)..."
    $User = New-MgUser -AccountEnabled `
        -DisplayName $DisplayName `
        -MailNickname $MailNickname `
        -UserPrincipalName $UserPrincipalName `
        -PasswordProfile @{ forceChangePasswordNextSignIn = $true; password = $Password } `
        -ErrorAction Stop

    Write-Log "User created successfully. User ID: $($User.Id)"
}
catch {
    Write-Log "Error creating user: $($_.Exception.Message)" "ERROR"
    Disconnect-MgGraph
    exit 1
}

# ===========================
# Step 2: Add User to HR_Users Group
# ===========================
try {
    Write-Log "Searching for group '$GroupName'..."
    $Group = Get-MgGroup -Filter "DisplayName eq '$GroupName'" -ErrorAction Stop

    if ($Group) {
        Write-Log "Group found: $($Group.Id). Adding user to group..."
        New-MgGroupMember -GroupId $Group.Id -DirectoryObjectId $User.Id -ErrorAction Stop
        Write-Log "User added to group '$GroupName' successfully."
    }
    else {
        Write-Log "Group '$GroupName' not found in Azure AD." "ERROR"
    }
}
catch {
    Write-Log "Error adding user to group '$GroupName': $($_.Exception.Message)" "ERROR"
}

# ===========================
# Step 3: Assign RBAC Roles
# ===========================
foreach ($RoleName in $RolesToAssign) {
    try {
        Write-Log "Processing role assignment for: $RoleName..."
        $Role = Get-MgDirectoryRole | Where-Object { $_.DisplayName -eq $RoleName }

        # Enable role if inactive
        if (-not $Role) {
            Write-Log "Role '$RoleName' is not active. Attempting to enable it..."
            $RoleTemplate = Get-MgDirectoryRoleTemplate | Where-Object { $_.DisplayName -eq $RoleName }

            if ($RoleTemplate) {
                Enable-MgDirectoryRole -RoleTemplateId $RoleTemplate.Id | Out-Null
                $Role = Get-MgDirectoryRole | Where-Object { $_.DisplayName -eq $RoleName }
                Write-Log "Role '$RoleName' enabled successfully."
            }
            else {
                Write-Log "Role template for '$RoleName' not found. Skipping." "ERROR"
                continue
            }
        }

        # Assign role to user
        New-MgDirectoryRoleMember -DirectoryRoleId $Role.Id -DirectoryObjectId $User.Id -ErrorAction Stop
        Write-Log "Assigned role '$RoleName' to user successfully."
    }
    catch {
        Write-Log "Error assigning role '$RoleName': $($_.Exception.Message)" "ERROR"
    }
}

# ===========================
# Cleanup
# ===========================
try {
    Disconnect-MgGraph
    Write-Log "Disconnected from Microsoft Graph. Script completed successfully."
}
catch {
    Write-Log "Error disconnecting from Microsoft Graph: $($_.Exception.Message)" "ERROR"
}

Write-Host "All tasks completed successfully for $DisplayName!"
Write-Host "Log file saved to: $LogFile"
