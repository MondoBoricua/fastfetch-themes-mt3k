# fastfetch-themes-mt3k.ps1 - Auto-detecting fastfetch theme selector for Windows
# Detects themes automatically from Large-Themes, Small-Themes, and Visuals-Themes

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = "$env:USERPROFILE\.config\fastfetch"

# Theme storage
$Themes = @()
$ThemePaths = @()
$ThemeTypes = @()
$LogoProtocol = ""

function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color -NoNewline
}

function Write-ColorLine {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Scan-Themes {
    $script:Themes = @()
    $script:ThemePaths = @()
    $script:ThemeTypes = @()

    foreach ($category in @("Large-Themes", "Small-Themes", "Visuals-Themes")) {
        $dir = Join-Path $ScriptDir $category
        if (-not (Test-Path $dir)) { continue }

        Get-ChildItem -Path $dir -Directory | ForEach-Object {
            $themeName = $_.Name
            if ($themeName -eq "Default") { return }

            $configJsonc = Join-Path $_.FullName "fastfetch\config.jsonc"
            $configJson = Join-Path $_.FullName "fastfetch\config.json"

            if ((Test-Path $configJsonc) -or (Test-Path $configJson)) {
                $script:Themes += $themeName
                $script:ThemePaths += $_.FullName
                $script:ThemeTypes += $category
            }
        }
    }
}

function Show-Banner {
    Clear-Host
    Write-ColorLine "  __           _    __     _       _       " "Red"
    Write-ColorLine " / _| __ _ ___| |_ / _| __|_|_ ___| |__    " "DarkYellow"
    Write-ColorLine "| |_ / _`` / __| __| |_ / _ \ __/ __| '_ \   " "Green"
    Write-ColorLine "|  _| (_| \__ \ |_|  _|  __/ || (__| | | |  " "Cyan"
    Write-ColorLine "|_|  \__,_|___/\__|_|  \___|\\__\___|_| |_|  " "Blue"
    Write-ColorLine "        themes-mt3k (Windows)" "White"
    Write-Host ""
    Write-Color "[L]" "Red"; Write-Color "=Large  " "Gray"
    Write-Color "[S]" "Green"; Write-Color "=Small  " "Gray"
    Write-Color "[V]" "DarkYellow"; Write-ColorLine "=Visual" "Gray"
    Write-ColorLine "--------------------------------------------" "Gray"
}

function Show-Themes {
    $currentCat = ""
    $col = 0
    $colWidth = 18
    $cols = 4

    for ($i = 0; $i -lt $Themes.Count; $i++) {
        $cat = $ThemeTypes[$i]
        $num = $i + 1

        # Category header
        if ($cat -ne $currentCat) {
            if ($col -ne 0) { Write-Host "" }
            $col = 0
            $currentCat = $cat
            Write-Host ""

            switch ($cat) {
                "Large-Themes"   { Write-ColorLine "=== LARGE ================================================" "Red" }
                "Small-Themes"   { Write-ColorLine "=== SMALL ================================================" "Green" }
                "Visuals-Themes" { Write-ColorLine "=== VISUAL ===============================================" "DarkYellow" }
            }
        }

        # Theme color
        $color = switch ($cat) {
            "Large-Themes"   { "Red" }
            "Small-Themes"   { "Green" }
            "Visuals-Themes" { "DarkYellow" }
            default { "White" }
        }

        $numStr = "[{0:D2}]" -f $num
        $nameStr = $Themes[$i].PadRight($colWidth).Substring(0, $colWidth)

        Write-Color $numStr "Cyan"
        Write-Color $nameStr $color
        $col++

        if ($col -ge $cols) {
            Write-Host ""
            $col = 0
        }
    }

    if ($col -ne 0) { Write-Host "" }
    Write-Host ""
    Write-ColorLine "=========================================================" "Gray"
    Write-Color "[x]" "Red"; Write-Color " Exit    " "White"
    Write-Color "[b]" "Green"; Write-Color " Backup    " "White"
    Write-Color "[r]" "DarkYellow"; Write-ColorLine " Restore" "White"
}

function Backup-Config {
    $timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
    $backupDir = Join-Path $ScriptDir "Backup-$timestamp"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    if (Test-Path $ConfigDir) {
        Copy-Item -Path $ConfigDir -Destination $backupDir -Recurse
        Write-ColorLine "Backup saved to: $backupDir" "Green"
    } else {
        Write-ColorLine "No config to backup" "Yellow"
    }
    Start-Sleep -Seconds 1.5
}

function Restore-Config {
    $latest = Get-ChildItem -Path $ScriptDir -Directory -Filter "Backup-*" |
              Sort-Object Name -Descending |
              Select-Object -First 1

    if ($latest -and (Test-Path (Join-Path $latest.FullName "fastfetch"))) {
        if (Test-Path $ConfigDir) { Remove-Item -Path $ConfigDir -Recurse -Force }
        Copy-Item -Path (Join-Path $latest.FullName "fastfetch") -Destination $ConfigDir -Recurse
        Write-ColorLine "Restored from: $($latest.FullName)" "Green"
        Start-Sleep -Seconds 1
        & fastfetch
    } else {
        Write-ColorLine "No backup found" "Red"
        Start-Sleep -Seconds 1.5
    }
}

function Prompt-Protocol {
    Write-Host ""
    Write-ColorLine "Choose the image rendering protocol for this theme:" "Yellow"
    Write-ColorLine "-------------------------------------------------------------------" "Gray"
    Write-Color "[1]" "Green"; Write-ColorLine " auto          - (Default) Auto-detect. Works on Kitty, Ghostty." "White"
    Write-Color "[2]" "Green"; Write-ColorLine " kitty         - Standard Kitty protocol. Best for Kitty terminal." "White"
    Write-Color "[3]" "Green"; Write-ColorLine " kitty-direct  - Fastest. WezTerm, Warp, Kitty, Ghostty (PNG only)." "White"
    Write-Color "[4]" "Green"; Write-ColorLine " iterm         - iTerm2 protocol. iTerm2, WezTerm, Konsole." "White"
    Write-Color "[5]" "Green"; Write-ColorLine " sixel         - Sixel graphics support (foot, Contour)." "White"
    Write-ColorLine "-------------------------------------------------------------------" "Gray"

    while ($true) {
        Write-Color "mt3k" "Green"
        Write-Color "@" "White"
        Write-ColorLine "protocol" "Red"
        Write-Color "> " "Red"
        $choice = Read-Host

        switch ($choice) {
            "1" { $script:LogoProtocol = "auto"; return }
            "2" { $script:LogoProtocol = "kitty"; return }
            "3" { $script:LogoProtocol = "kitty-direct"; return }
            "4" { $script:LogoProtocol = "iterm"; return }
            "5" { $script:LogoProtocol = "sixel"; return }
            default { Write-ColorLine "Invalid choice. Please select 1-5." "Red" }
        }
    }
}

function Apply-Theme {
    param([int]$Index)

    $themePath = $ThemePaths[$Index]
    $themeName = $Themes[$Index]
    $themeType = $ThemeTypes[$Index]

    Write-Color "Applying " "Cyan"
    Write-Color $themeName "Green"
    Write-ColorLine "..." "Cyan"
    Start-Sleep -Milliseconds 300

    # Clean and copy
    if (Test-Path $ConfigDir) { Remove-Item -Path $ConfigDir -Recurse -Force }
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    Copy-Item -Path (Join-Path $themePath "fastfetch\*") -Destination $ConfigDir -Recurse

    $configFile = Join-Path $ConfigDir "config.jsonc"

    # For visual themes, fix image path and protocol
    if ($themeType -eq "Visuals-Themes" -and (Test-Path $configFile)) {
        $content = Get-Content $configFile -Raw

        # Update protocol in logo block
        $content = $content -replace '("logo":\s*\{[^}]*"type":\s*")[^"]*(")', "`$1$LogoProtocol`$2"

        # Update source path - convert to Windows path format
        $configDirEscaped = $ConfigDir -replace '\\', '/'
        $content = $content -replace '"source":\s*"([^"/][^"]*)"', "`"source`": `"$configDirEscaped/`$1`""

        Set-Content -Path $configFile -Value $content -NoNewline
    }

    Clear-Host
    Write-Color "Running fastfetch with " "Cyan"
    Write-Color $themeName "Green"
    Write-ColorLine "..." "Cyan"
    Write-Host ""
    & fastfetch
}

# Main loop
function Main {
    Scan-Themes

    if ($Themes.Count -eq 0) {
        Write-ColorLine "No themes found!" "Red"
        exit 1
    }

    while ($true) {
        Show-Banner
        Show-Themes
        Write-Host ""
        Write-Color "mt3k" "Green"
        Write-Color "@" "White"
        Write-ColorLine "themes" "Red"
        Write-Color "> " "Red"
        $choice = Read-Host

        switch -Regex ($choice) {
            "^[xXqQ]$" {
                Clear-Host
                Write-ColorLine "Goodbye!" "Red"
                exit 0
            }
            "^[bB]$" {
                Backup-Config
            }
            "^[rR]$" {
                Restore-Config
            }
            "^\d+$" {
                $idx = [int]$choice - 1
                if ($idx -ge 0 -and $idx -lt $Themes.Count) {
                    if ($ThemeTypes[$idx] -eq "Visuals-Themes") {
                        Prompt-Protocol
                    }
                    Apply-Theme -Index $idx

                    Write-Host ""
                    Write-ColorLine "Press enter to continue..." "Green"
                    Read-Host | Out-Null
                } else {
                    Write-ColorLine "Invalid selection" "Red"
                    Start-Sleep -Milliseconds 500
                }
            }
            default {
                Write-ColorLine "Invalid selection" "Red"
                Start-Sleep -Milliseconds 500
            }
        }
    }
}

Main
