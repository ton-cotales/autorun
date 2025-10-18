<#
    Script: autorun.ps1
    Author: Anthony Cotales
    Email: anthony.cotales.civ@gmail.com
    Version: 1.2.0
    Description: This is a custom script that will install basic applications for windows.
#>

$logHeader = @"
------------------------------------------------------
                 autorun.exe -> log.txt               
------------------------------------------------------

"@

$logFooter = @"

------------------------------------------------------
                 Author: Anthony Cotales              
            Email: anthony.cotales.civ@gmail.com
------------------------------------------------------
"@


# Applications folder
$applicationsDir = ".\applications"

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

# -- Silent application installation
if (Test-Path -Path $applicationsDir) {
    # Full path to the Applications folder
    $applicationsPath = Resolve-Path -Path ".\applications"

    # Get all .exe files
    $exeFiles = Get-ChildItem -Path $applicationsPath -Filter *.exe -ErrorAction SilentlyContinue

    # Also write to host for realtime feedback for debugging
    Write-Host "Installation started at $(Get-Date)"
    Write-Log "Installation started at $(Get-Date)`n"

    # Define silent arguments per installer
    $installArgsMap = @{
        "7z"                 = "/S"
        "chromestandalonesetup" = "/silent /install"
        "vlc"                  = "/S"
        "winrar"               = "/S"
    }

    foreach ($exe in $exeFiles) {
        $exeName = $exe.Name.ToLower()
        $customArgs = $null

        # Find matching arguments based on the filename
        foreach ($key in $installArgsMap.Keys) {
            if ($exeName -like "*$key*") {
                $customArgs = $installArgsMap[$key]
                break
            }
        }

        # Fallback to a basic silent arg
        if (-not $customArgs) {
            try {
                $fallback = Start-Process -FilePath $exe.FullName `
                                        -Wait `
                                        -PassThru `
                                        -NoNewWindow `
                                        -ErrorAction Stop

                if ($fallback.ExitCode -eq 0) {
                    Write-Host "SUCCESS: $($exe.Name)" -ForegroundColor Green
                    Write-Log "SUCCESS: [Fallback] $($exe.Name) at $(Get-Date)"
                } else {
                    Write-Host "EXIT CODE $($fallback.ExitCode): $($exe.Name)" -ForegroundColor Yellow
                    Write-Log "WARNING: [Fallback] $($exe.Name) exited with code $($fallback.ExitCode) at $(Get-Date)"
                }
            }
            catch {
                Write-Host "ERROR installing $($exe.Name): $_" -ForegroundColor Red
                Write-Log "ERROR: [Fallback] $($exe.Name) failed at $(Get-Date) - $_"
            }
        }
        else {
            try {
                $process = Start-Process -FilePath $exe.FullName `
                                        -ArgumentList $customArgs `
                                        -Wait `
                                        -PassThru `
                                        -NoNewWindow `
                                        -ErrorAction Stop

                if ($process.ExitCode -eq 0) {
                    Write-Host "SUCCESS: $($exe.Name)" -ForegroundColor Green
                    Write-Log "SUCCESS: $($exe.Name) at $(Get-Date)"
                } else {
                    Write-Host "EXIT CODE $($process.ExitCode): $($exe.Name)" -ForegroundColor Yellow
                    Write-Log "WARNING: $($exe.Name) exited with code $($process.ExitCode) at $(Get-Date)"
                }
            }
            catch {
                Write-Host "ERROR installing $($exe.Name): $_" -ForegroundColor Red
                Write-Log "ERROR: $($exe.Name) failed at $(Get-Date) - $_"
            }
        }
    }

    Write-Host "Installation ended at $(Get-Date)"
    Write-Log "`nInstallation ended at $(Get-Date)"

    Start-Sleep -Seconds 2
} else {
    Write-Host "applications folder not found." -ForegroundColor Yellow
    Write-Log "WARNING: applications folder not found."
}


# -- Time zone configuration
Write-Host "Setting time zone to (UTC+08:00) Kuala Lumpur..."
Write-Log "`nSetting time zone to (UTC+08:00) Kuala Lumpur..."

try {
    # Set the time zone
    Set-TimeZone -Id "Singapore Standard Time" -ErrorAction SilentlyContinue;

    # Start time service if not running
    Start-Service w32time -ErrorAction SilentlyContinue;

    # Optional: Set time server
    w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:yes /update

    # Restart time service to apply changes
    Restart-Service w32time -ErrorAction SilentlyContinue;

    # Sync time
    w32tm /resync

    Write-Host "SUCCESS: Time zone and time sync configuration completed." -ForegroundColor Green
    Write-Log "SUCCESS: Time zone and time sync configuration completed."
} catch {
    Write-Host "ERROR: Failed to set time zone - $_" -ForegroundColor Red
    Write-Log "ERROR: Failed to set time zone - $_"
}


# -- Copy WinRAR license (rarreg.key) to installation directory.
Write-Log "`nCopying WinRAR license (rarreg.key)"

# Path to the Installers folder and the rarreg.key file
$keyFile = Resolve-Path -Path ".\winrar_key\rarreg.key"

# Potential WinRAR installation directories
$possiblePaths = @(
    "$env:ProgramFiles\WinRAR",
    "$env:ProgramFiles(x86)\WinRAR"
)

# Find the actual WinRAR install path
$winrarPath = $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $winrarPath) {
    Write-Host "WinRAR installation directory not found." -ForegroundColor Red
    Write-Log "WARNING: WinRAR installation directory not found."
} elseif (-not (Test-Path $keyFile)) {
    Write-Host "rarreg.key file not found in winrar_key folder." -ForegroundColor Red
    Write-Log "WARNING: rarreg.key file not found in winrar_key folder."
} else {
    try {
        # Copy the key file
        Copy-Item -Path $keyFile -Destination $winrarPath -Force -ErrorAction SilentlyContinue
        Write-Host "rarreg.key successfully copied to: $winrarPath" -ForegroundColor Green
        Write-Log "SUCCESS: rarreg.key successfully copied to: $winrarPath"
    }
    catch {
        Write-Host "Failed to copy rarreg.key: $_" -ForegroundColor Red
        Write-Log "ERROR: Failed to copy rarreg.key: $_"
    }
}


# -- Activating Microsoft Windows Operating System
Write-Log "`nActivating microsoft windows operating system"

try {
    # Online silent permanent digital license activation
    & ([ScriptBlock]::Create((New-Object Net.WebClient).DownloadString('https://get.activated.win'))) /HWID /S
    Write-Host "Windows is activated permanently." -ForegroundColor Green
    Write-Log "SUCCESS: Windows is activated permanently."
}
catch {
    Write-Host "Failed to activate windows: $_" -ForegroundColor Red
    Write-Log "ERROR: Failed to activate windows: $_"
}

Write-Host $logFooter
Write-Log $logFooter

# -- Showing messagebox of the complete procedure
[System.Windows.Forms.MessageBox]::Show(
    $null,
    "Automated Installer COMPLETE!",
    "autorun.exe",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information)

if (Test-Path $logFile) {
    Start-Process notepad.exe $logFile
}

