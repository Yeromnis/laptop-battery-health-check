# lbhc
# Laptop Battery Health Check v1.0
# https://github.com/Yeromnis/laptop-battery-health-check


# UI messages
$translations = @{
    "fr-FR" = @{
        "REPORT_TITLE"              = "=== BILAN DE SANT$([char]0x00C9) DE LA BATTERIE ==="
        "ORIGINAL_BATTERY_CAPACITY" = "Capacit$([char]0x00E9) d'origine : {0} mWh"
        "CURRENT_BATTERY_CAPACITY"  = "Capacit$([char]0x00E9) actuelle  : {0} mWh"
        "HEALTH"                    = "Sant$([char]0x00E9) de la batterie        : {0} %"
        "WEAR"                      = "Taux d'usure de la batterie : {0} %"
        "REPORT_GENERATION_ERROR"   = "ERREUR : Impossible de produire le rapport système."
        "REPORT_ERROR"              = "ERREUR : Impossible de lire les informations concernant la batterie."  
        "PRESS_ANY_KEY"             = "Pressez une touche..."
        "AUTHOR"                    = "`nlbhc - Laptop Battery Health Check v1.0`nhttps://github.com/Yeromnis/laptop-battery-health-check`n"      
    }
    "en-US" = @{
        "REPORT_TITLE"              = "=== BATTERY HEALTH CHECKUP ==="
        "ORIGINAL_BATTERY_CAPACITY" = "Original Battery Capacity: {0} mWh"
        "CURRENT_BATTERY_CAPACITY"  = "Current Battery Capacity : {0} mWh"
        "HEALTH"                    = "Battery Health   : {0} %"
        "WEAR"                      = "Battery Wear Rate: {0} %"
        "REPORT_GENERATION_ERROR"   = "ERROR: Unable to produce the OS report."
        "REPORT_ERROR"              = "ERROR: Unable to read battery data."
        "PRESS_ANY_KEY"             = "Press any key..."
        "AUTHOR"                    = "`nlbhc - Laptop Battery Health Check v1.0`nhttps://github.com/Yeromnis/laptop-battery-health-check`n"
    }
}


# UI language
$DefaultLanguage = "en-US"
$uiLanguage = (Get-Culture).Name

function Get-TranslatedMessage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$MessageKey
    )
    if ($Translations.ContainsKey($uiLanguage)) {
        $message = $Translations[$uiLanguage][$MessageKey]
    }
    else {
        $message = $Translations[$DefaultLanguage][$MessageKey]
    }
    return $message
}


# Author
Write-Host(Get-TranslatedMessage -MessageKey "AUTHOR") -ForegroundColor Cyan


# Generate the report in the TEMP folder
$reportPath = "$env:TEMP\battery-report.xml"
powercfg /batteryreport /output $reportPath /xml | Out-Null

# Check if the report file exists
if (-not (Test-Path $reportPath)) {
    Write-Error(Get-TranslatedMessage -MessageKey "REPORT_GENERATION_ERROR")
    exit 1
}

# Load the report file XML content
[xml]$batteryReport = Get-Content $reportPath

# Read and compute information
$designCapacity = $batteryReport.BatteryReport.Batteries.Battery.DesignCapacity
$fullChargeCapacity = $batteryReport.BatteryReport.Batteries.Battery.FullChargeCapacity
$health = [math]::Round(($fullChargeCapacity / $designCapacity) * 100, 2)
$wear = 100 - $health

# Display results
if ($designCapacity -and $fullChargeCapacity) {

    Write-Host(Get-TranslatedMessage -MessageKey "REPORT_TITLE") -ForegroundColor Cyan
    $separatorLength = (Get-TranslatedMessage -MessageKey "REPORT_TITLE").Length

    Write-Host((Get-TranslatedMessage -MessageKey "ORIGINAL_BATTERY_CAPACITY") -f $designCapacity) -ForegroundColor Gray
    Write-Host((Get-TranslatedMessage -MessageKey "CURRENT_BATTERY_CAPACITY") -f $fullChargeCapacity) -ForegroundColor Gray

    Write-Host('-' * $separatorLength) -ForegroundColor Cyan 
            
    # Color / Status
    if ($health -ge 75) { $color = "Green" }
    elseif ($health -ge 50) { $color = "Yellow" }
    else { $color = "Red" }

    Write-Host((Get-TranslatedMessage -MessageKey "HEALTH") -f $health) -ForegroundColor $color
    Write-Host((Get-TranslatedMessage -MessageKey "WEAR") -f $wear) -ForegroundColor $color

    Write-Host('=' * $separatorLength) -ForegroundColor Cyan
}
else {
    Write-Error(Get-TranslatedMessage -MessageKey "REPORT_ERROR")
}
    

# Delete temp file
Remove-Item $reportPath -Force


# Get execution context to wait or not a keyboard input
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class ConsoleHelper {
    [DllImport("kernel32.dll")]
    public static extern int GetConsoleProcessList(IntPtr[] lpprocess, int nSize);
}
"@

$processList = New-Object IntPtr[] 10
$processCount = [ConsoleHelper]::GetConsoleProcessList($processList, $processList.Length)

if ($processCount -eq 1) {
    Write-Host ""
    Write-Host(Get-TranslatedMessage -MessageKey "PRESS_ANY_KEY") -ForegroundColor White
    $k = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
