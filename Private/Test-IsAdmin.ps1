Function Test-IsAdmin {
<#
.Synopsis
    Checks if the current console session is running elevated (with admin privileges) or not
#>
    $CurrentId = [Security.Principal.WindowsIdentity]::GetCurrent()
    $AdminRole = [Security.Principal.WindowsBuiltinRole]::Administrator
    $IsAdmin   = [Security.Principal.WindowsPrincipal]::new($CurrentId).IsInRole($AdminRole)
    Write-Output $IsAdmin
}