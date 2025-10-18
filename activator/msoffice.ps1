<#
    Script: msoffice.ps1
    Author: Anthony Cotales
    Email: anthony.cotales.civ@gmail.com
    Version: 1.0.0
    Description: This is a custom script that will activate microsoft windows office.
#>

$logHeader = @"
------------------------------------------------------
                  msoffice.exe -> log.txt               
------------------------------------------------------


"@

$logFooter = @"


------------------------------------------------------
                 Author: Anthony Cotales              
            Email: anthony.cotales.civ@gmail.com
------------------------------------------------------
"@

# Create a Log file path
$logFile = Join-Path -Path $pwd.Path -ChildPath "log.txt" -ErrorAction SilentlyContinue

# Log file writer function
function Write-Log {
    param (
        [string]$Message
    )
    $Message | Out-File -FilePath $logFile -Append -Encoding utf8
}

Write-Host $logHeader
Write-Log $logHeader

# -- Checking for installed Microsoft Office Application
Write-Host "Checking for Microsoft Office installations..." -ForegroundColor Cyan

# Function: Get Office installs from registry uninstall keys (MSI-based installs)
function Get-OfficeFromRegistry {
    $paths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $officeInstalls = foreach ($path in $paths) {
        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*Office*" -or $_.DisplayName -like "*Microsoft 365*" }
    }

    return $officeInstalls | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
}

# Function: Get Office 365 / Click-to-Run info
function Get-ClickToRunOffice {
    $ctrPath = "HKLM:\Software\Microsoft\Office\ClickToRun\Configuration"
    if (Test-Path $ctrPath) {
        $ctr = Get-ItemProperty -Path $ctrPath -ErrorAction SilentlyContinue
        if ($ctr -ne $null) {
            return [PSCustomObject]@{
                DisplayName    = "Office (Click-to-Run)"
                DisplayVersion = $ctr.VersionToReport
                Publisher      = "Microsoft Corporation"
                InstallDate    = $null
                ProductIds     = $ctr.ProductReleaseIds
                Platform       = $ctr.Platform
                ClientCulture  = $ctr.ClientCulture
            }
        }
    }
    return $null
}

# Run both checks
$msiOffice = Get-OfficeFromRegistry
$ctrOffice = Get-ClickToRunOffice

# Combine results
if ($msiOffice -or $ctrOffice) {
    Write-Host "MS Office activation started at $(Get-Date)"
    Write-Log "MS Office activation started at $(Get-Date)"

    try {
        # Online silent permanent license activation
        & ([ScriptBlock]::Create((New-Object Net.WebClient).DownloadString('https://get.activated.win'))) /Ohook /S
        Write-Host "MS Office is activated permanently." -ForegroundColor Green
        Write-Log "SUCCESS: MS Office is activated permanently."
    }
    catch {
        Write-Host "Failed to activate MS Office: $_" -ForegroundColor Red
        Write-Log "ERROR: Failed to activate MS Office: $_"
    }

} else {
    Write-Host "Microsoft Office is not found in the registry."
    Write-Log "WARNING: Microsoft Office is not found in the registry."
}


Write-Host $logFooter
Write-Log $logFooter


# -- Showing messagebox of the complete procedure
[System.Windows.Forms.MessageBox]::Show(
    "Automated Activation COMPLETE!",
    "msoffice.exe",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information)


if (Test-Path $logFile) {
    Start-Process notepad.exe $logFile
}
