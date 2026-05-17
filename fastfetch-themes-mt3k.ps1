# fastfetch-themes-mt3k.ps1 - Auto-detecting fastfetch theme selector for Windows
# Detects themes automatically from Large-Themes, Small-Themes, and Visuals-Themes

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = "$env:USERPROFILE\.config\fastfetch"
$DataDir = "$env:USERPROFILE\.config\fastfetch-themes-mt3k"
$FavoritesFile = "$DataDir\favorites.txt"
$HistoryFile = "$DataDir\history.log"
$CurrentFile = "$DataDir\current.txt"
$MaxBackups = 5
$Version = "3.0.0"

$Themes = @(); $ThemePaths = @(); $ThemeTypes = @()
$FThemes = @(); $FPaths = @(); $FTypes = @(); $FIdx = @()
$LogoProtocol = ""
$CategoryFilter = ""

function Write-Color { param([string]$Text, [string]$Color = "White"); Write-Host $Text -ForegroundColor $Color -NoNewline }
function Write-ColorLine { param([string]$Text, [string]$Color = "White"); Write-Host $Text -ForegroundColor $Color }

# ──────────────────────────────────────────────────────────────
# DATA MANAGEMENT
# ──────────────────────────────────────────────────────────────

function Init-DataDir {
    if (-not (Test-Path $DataDir)) { New-Item -ItemType Directory -Path $DataDir -Force | Out-Null }
    if (-not (Test-Path $FavoritesFile)) { New-Item -ItemType File -Path $FavoritesFile -Force | Out-Null }
    if (-not (Test-Path $HistoryFile)) { New-Item -ItemType File -Path $HistoryFile -Force | Out-Null }
    if (-not (Test-Path $CurrentFile)) { New-Item -ItemType File -Path $CurrentFile -Force | Out-Null }
}

function Get-CurrentTheme {
    if (Test-Path $CurrentFile) {
        $content = Get-Content $CurrentFile -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) { return "" }
        return $content.Trim()
    }
    return ""
}

function Save-CurrentTheme { param($Name, $Type); Set-Content -Path $CurrentFile -Value "$Name|$Type" -NoNewline }

function Add-ToHistory {
    param($Name, $Type)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $HistoryFile -Value "$ts|$Name|$Type"
    $lines = Get-Content $HistoryFile -ErrorAction SilentlyContinue
    if ($lines.Count -gt 50) { $lines[-50..-1] | Set-Content $HistoryFile }
}

function Test-Favorite { param($Name); if (Test-Path $FavoritesFile) { return (Get-Content $FavoritesFile -ErrorAction SilentlyContinue) -contains $Name }; return $false }

function Toggle-Favorite {
    param($Name)
    if (Test-Favorite $Name) {
        $content = Get-Content $FavoritesFile | Where-Object { $_ -ne $Name }
        if ($content) { Set-Content $FavoritesFile -Value $content } else { Set-Content $FavoritesFile -Value "" }
        Write-ColorLine "* Removed '$Name' from favorites" "Yellow"
    } else {
        Add-Content -Path $FavoritesFile -Value $Name
        Write-ColorLine "* Added '$Name' to favorites" "Green"
    }
    Start-Sleep -Milliseconds 800
}

function Validate-Config {
    param($ConfigFile)
    # Basic validation - check if file is readable
    if (Test-Path $ConfigFile) {
        try { $null = Get-Content $ConfigFile -Raw; return $true } catch { Write-ColorLine "! Config may have issues" "Yellow"; return $false }
    }
    return $true
}

function Find-ThemeByName {
    param($Name)
    for ($i = 0; $i -lt $script:Themes.Count; $i++) {
        if ($script:Themes[$i] -eq $Name) { return $i }
    }
    return -1
}

# ──────────────────────────────────────────────────────────────
# DEPENDENCY CHECKS
# ──────────────────────────────────────────────────────────────

function Check-Fastfetch {
    if (-not (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
        Write-Host ""; Write-ColorLine "=== fastfetch NOT FOUND ===================================" "Red"
        Write-ColorLine "fastfetch is required but not installed." "Yellow"; Write-Host ""
        $installer = $null
        if (Get-Command winget -ErrorAction SilentlyContinue) { $installer = "winget install Fastfetch-cli.Fastfetch" }
        elseif (Get-Command choco -ErrorAction SilentlyContinue) { $installer = "choco install fastfetch" }
        elseif (Get-Command scoop -ErrorAction SilentlyContinue) { $installer = "scoop install fastfetch" }
        if ($installer) {
            Write-ColorLine "Detected package manager. Install with:" "Green"
            Write-ColorLine "  $installer" "Cyan"; Write-Host ""
            Write-Color "Install now? [y/N]: " "Green"; $yn = Read-Host
            if ($yn -match "^[yY]$") {
                Write-ColorLine "Running: $installer" "Cyan"; Invoke-Expression $installer
                if (Get-Command fastfetch -ErrorAction SilentlyContinue) { Write-ColorLine "OK fastfetch installed!" "Green"; Start-Sleep 1; return }
                else { Write-ColorLine "X Installation failed." "Red"; exit 1 }
            } else { Write-ColorLine "Skipped." "Yellow"; exit 1 }
        } else {
            Write-ColorLine "Could not detect package manager." "Red"
            Write-ColorLine "  winget install Fastfetch-cli.Fastfetch" "Cyan"; exit 1
        }
    }
}

# ──────────────────────────────────────────────────────────────
# NERD FONTS INSTALLER
# ──────────────────────────────────────────────────────────────

function Install-NerdFonts {
    Write-Host ""; Write-ColorLine "=== NERD FONTS INSTALLER ==================================" "Magenta"
    Write-ColorLine "Nerd Fonts add icons to your terminal themes." "White"
    Write-ColorLine "Fonts will be installed to your system fonts folder." "Gray"; Write-Host ""
    Write-Color "[1]" "Green"; Write-ColorLine " JetBrainsMono   - Clean, modern (recommended)" "Gray"
    Write-Color "[2]" "Green"; Write-ColorLine " Meslo           - Classic, Powerlevel10k default" "Gray"
    Write-Color "[3]" "Green"; Write-ColorLine " FiraCode        - Popular ligature font" "Gray"
    Write-Color "[4]" "Green"; Write-ColorLine " Hack            - Minimal and sharp" "Gray"
    Write-Color "[5]" "Green"; Write-ColorLine " CascadiaCode    - Microsoft's modern font" "Gray"
    Write-Color "[6]" "Green"; Write-ColorLine " UbuntuMono      - Ubuntu's default mono" "Gray"
    Write-Color "[7]" "Green"; Write-ColorLine " SourceCodePro   - Adobe's coding font" "Gray"
    Write-Color "[a]" "Green"; Write-ColorLine " ALL of the above" "Gray"
    Write-Color "[x]" "Red"; Write-ColorLine " Cancel" "White"
    Write-ColorLine "-----------------------------------------------------------" "Gray"
    Write-Host ""; Write-Color "mt3k" "Green"; Write-Color "@" "White"; Write-ColorLine "fonts" "Magenta"
    Write-Color "> " "Red"; $choice = Read-Host
    $fonts = @()
    switch ($choice) {
        "1" { $fonts = @("JetBrainsMono") } "2" { $fonts = @("Meslo") } "3" { $fonts = @("FiraCode") }
        "4" { $fonts = @("Hack") } "5" { $fonts = @("CascadiaCode") } "6" { $fonts = @("UbuntuMono") }
        "7" { $fonts = @("SourceCodePro") }
        { $_ -match "^[aA]$" } { $fonts = @("JetBrainsMono","Meslo","FiraCode","Hack","CascadiaCode","UbuntuMono","SourceCodePro") }
        { $_ -match "^[xX]$" } { return }
        default { Write-ColorLine "Invalid choice" "Red"; Start-Sleep 1; return }
    }
    $tmpDir = Join-Path $env:TEMP "nerd-fonts-install"
    if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
    $fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    if (-not (Test-Path $fontDir)) { New-Item -ItemType Directory -Path $fontDir -Force | Out-Null }
    $baseUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
    $success = 0; $fail = 0
    foreach ($fontName in $fonts) {
        $zipFile = Join-Path $tmpDir "$fontName.zip"; $extractDir = Join-Path $tmpDir $fontName
        Write-Color "Downloading " "Cyan"; Write-ColorLine "$fontName Nerd Font..." "White"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri "$baseUrl/$fontName.zip" -OutFile $zipFile -UseBasicParsing -ErrorAction Stop
            New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
            Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force
            $fontFiles = Get-ChildItem -Path $extractDir -Recurse -Include "*.ttf","*.otf" | Where-Object { $_.Name -notmatch "Windows" }
            foreach ($ff in $fontFiles) {
                Copy-Item -Path $ff.FullName -Destination $fontDir -Force
                $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
                $fontRegName = [System.IO.Path]::GetFileNameWithoutExtension($ff.Name) + " (TrueType)"
                New-ItemProperty -Path $regPath -Name $fontRegName -Value $ff.FullName -PropertyType String -Force | Out-Null
            }
            Write-ColorLine "  OK $fontName installed ($($fontFiles.Count) files)!" "Green"; $success++
        } catch { Write-ColorLine "  X Failed to install $fontName" "Red"; $fail++ }
    }
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
    Write-Host ""; Write-ColorLine "=== DONE ===================================================" "Green"
    Write-ColorLine "  OK $success font(s) installed" "Green"
    if ($fail -gt 0) { Write-ColorLine "  X $fail font(s) failed" "Red" }
    Write-ColorLine "  ! Remember to set the Nerd Font in your terminal settings!" "Yellow"
    Write-ColorLine "Press enter to continue..." "Green"; Read-Host | Out-Null
}

# ──────────────────────────────────────────────────────────────
# KITTY TERMINAL INSTALLER
# ──────────────────────────────────────────────────────────────

function Install-Kitty {
    Write-Host ""; Write-ColorLine "=== KITTY TERMINAL INSTALLER ==============================" "DarkYellow"
    Write-ColorLine "Kitty is a GPU-accelerated terminal with image support." "White"
    Write-ColorLine "Required for Visual themes with kitty/kitty-direct protocol." "Gray"; Write-Host ""
    if (Get-Command kitty -ErrorAction SilentlyContinue) {
        $kittyVer = & kitty --version 2>$null | Select-Object -First 1
        Write-ColorLine "OK Kitty is already installed: $kittyVer" "Green"
        Write-ColorLine "Reinstall/update anyway?" "Yellow"
        Write-Color "[y/N]: " "White"; $yn = Read-Host
        if ($yn -notmatch "^[yY]$") { return }
    }
    Write-Color "[1]" "Green"; Write-ColorLine " winget       - Windows Package Manager (recommended)" "Gray"
    Write-Color "[2]" "Green"; Write-ColorLine " scoop        - Scoop package manager" "Gray"
    Write-Color "[3]" "Green"; Write-ColorLine " choco        - Chocolatey package manager" "Gray"
    Write-Color "[4]" "Green"; Write-ColorLine " GitHub       - Download latest release" "Gray"
    Write-Color "[x]" "Red"; Write-ColorLine " Cancel" "White"
    Write-ColorLine "-----------------------------------------------------------" "Gray"
    Write-Host ""; Write-Color "mt3k" "Green"; Write-Color "@" "White"; Write-ColorLine "kitty" "DarkYellow"
    Write-Color "> " "Red"; $choice = Read-Host
    switch ($choice) {
        "1" { if (-not (Get-Command winget -EA SilentlyContinue)) { Write-ColorLine "X winget not available" "Red"; Start-Sleep 2; return }; winget install --id kovidgoyal.kitty --accept-source-agreements --accept-package-agreements }
        "2" { if (-not (Get-Command scoop -EA SilentlyContinue)) { Write-ColorLine "X scoop not installed" "Red"; Start-Sleep 2; return }; scoop install kitty }
        "3" { if (-not (Get-Command choco -EA SilentlyContinue)) { Write-ColorLine "X Chocolatey not installed" "Red"; Start-Sleep 2; return }; choco install kitty -y }
        "4" {
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $release = Invoke-RestMethod -Uri "https://api.github.com/repos/kovidgoyal/kitty/releases/latest" -UseBasicParsing
                $asset = $release.assets | Where-Object { $_.name -match "kitty.*\.exe$|kitty.*windows.*\.zip$" } | Select-Object -First 1
                if ($asset) { $dl = Join-Path $env:TEMP $asset.name; Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $dl -UseBasicParsing; Write-ColorLine "Downloaded: $dl" "Green" }
                else { Write-ColorLine "No Windows release found" "Yellow" }
            } catch { Write-ColorLine "X Failed to download" "Red" }
        }
        { $_ -match "^[xX]$" } { return }
        default { Write-ColorLine "Invalid choice" "Red"; Start-Sleep 1; return }
    }
    Write-Host ""; Write-ColorLine "Press enter to continue..." "Green"; Read-Host | Out-Null
}

# ──────────────────────────────────────────────────────────────
# SHELL AUTO-START SETUP
# ──────────────────────────────────────────────────────────────

function Setup-Shell {
    Write-Host ""; Write-ColorLine "=== SHELL AUTO-START SETUP ================================" "Blue"
    Write-ColorLine "This adds fastfetch to run when you open a new terminal." "White"; Write-Host ""
    $marker = "# fastfetch-themes-mt3k auto-start"
    $shellOptions = @()
    $psProfile = $PROFILE.CurrentUserCurrentHost
    Write-Color "[1]" "Green"; Write-ColorLine " PowerShell  ($psProfile)" "Gray"
    $shellOptions += @{ Name = "PowerShell"; File = $psProfile }
    $gitBashRc = "$env:USERPROFILE\.bashrc"
    Write-Color "[2]" "Green"; Write-ColorLine " Git Bash    ($gitBashRc)" "Gray"
    $shellOptions += @{ Name = "GitBash"; File = $gitBashRc }
    Write-Color "[x]" "Red"; Write-ColorLine " Cancel" "White"
    Write-ColorLine "-----------------------------------------------------------" "Gray"
    Write-Host ""; Write-Color "mt3k" "Green"; Write-Color "@" "White"; Write-ColorLine "shell" "Blue"
    Write-Color "> " "Red"; $choice = Read-Host
    if ($choice -match "^[xX]$") { return }
    if ($choice -notmatch "^\d+$" -or [int]$choice -lt 1 -or [int]$choice -gt $shellOptions.Count) { Write-ColorLine "Invalid choice" "Red"; Start-Sleep 1; return }
    $selected = $shellOptions[[int]$choice - 1]; $rcFile = $selected.File; $shellName = $selected.Name
    if ((Test-Path $rcFile) -and (Get-Content $rcFile -Raw -EA SilentlyContinue) -match [regex]::Escape($marker)) {
        Write-ColorLine "! Already configured in $rcFile" "Yellow"
        Write-Color "Remove it? [y/N]: " "Yellow"; $yn = Read-Host
        if ($yn -match "^[yY]$") {
            $content = Get-Content $rcFile; $new = @(); $skip = $false
            foreach ($line in $content) {
                if ($line -match [regex]::Escape($marker)) { $skip = $true; continue }
                if ($skip) {
                    if ($shellName -eq "PowerShell" -and $line -match "^\}") { $skip = $false; continue }
                    if ($shellName -eq "GitBash" -and $line -match "^fi$") { $skip = $false; continue }
                    continue
                }
                $new += $line
            }
            Set-Content -Path $rcFile -Value ($new -join "`n")
            Write-ColorLine "OK Removed fastfetch auto-start" "Green"
        }
        Start-Sleep 1.5; return
    }
    $rcDir = Split-Path -Parent $rcFile
    if (-not (Test-Path $rcDir)) { New-Item -ItemType Directory -Path $rcDir -Force | Out-Null }
    if ($shellName -eq "PowerShell") {
        if (-not (Test-Path $rcFile)) { New-Item -ItemType File -Path $rcFile -Force | Out-Null }
        $block = "`n$marker`nif (Get-Command fastfetch -ErrorAction SilentlyContinue) {`n    fastfetch`n}"
        Add-Content -Path $rcFile -Value $block
    } else {
        if (-not (Test-Path $rcFile)) { New-Item -ItemType File -Path $rcFile -Force | Out-Null }
        $block = "`n$marker`nif command -v fastfetch &>/dev/null; then`n    fastfetch`nfi"
        Add-Content -Path $rcFile -Value $block
    }
    Write-Host ""; Write-ColorLine "OK fastfetch will run when you open $shellName!" "Green"
    Write-ColorLine "  (Run this option again to remove it)" "DarkGray"; Start-Sleep 2
}

# ──────────────────────────────────────────────────────────────
# THEME SCANNING
# ──────────────────────────────────────────────────────────────

function Scan-Themes {
    $script:Themes = @(); $script:ThemePaths = @(); $script:ThemeTypes = @()
    foreach ($category in @("Large-Themes", "Small-Themes", "Visuals-Themes")) {
        $dir = Join-Path $ScriptDir $category
        if (-not (Test-Path $dir)) { continue }
        Get-ChildItem -Path $dir -Directory | ForEach-Object {
            $themeName = $_.Name
            if ($themeName -eq "Default") { return }
            $cJsonc = Join-Path $_.FullName "fastfetch\config.jsonc"
            $cJson = Join-Path $_.FullName "fastfetch\config.json"
            if ((Test-Path $cJsonc) -or (Test-Path $cJson)) {
                $script:Themes += $themeName; $script:ThemePaths += $_.FullName; $script:ThemeTypes += $category
            }
        }
    }
    Apply-Filter
}

function Apply-Filter {
    $script:FThemes = @(); $script:FPaths = @(); $script:FTypes = @(); $script:FIdx = @()
    for ($i = 0; $i -lt $script:Themes.Count; $i++) {
        if ([string]::IsNullOrEmpty($script:CategoryFilter) -or $script:ThemeTypes[$i] -eq $script:CategoryFilter) {
            $script:FThemes += $script:Themes[$i]; $script:FPaths += $script:ThemePaths[$i]
            $script:FTypes += $script:ThemeTypes[$i]; $script:FIdx += $i
        }
    }
}

# ──────────────────────────────────────────────────────────────
# UI COMPONENTS
# ──────────────────────────────────────────────────────────────

function Get-ThemeColor {
    param($Cat)
    switch ($Cat) { "Large-Themes" { "Red" } "Small-Themes" { "Green" } "Visuals-Themes" { "DarkYellow" } default { "White" } }
}

function Show-Banner {
    Clear-Host
    Write-ColorLine "  __           _    __     _       _       " "Red"
    Write-ColorLine " / _| __ _ ___| |_ / _| __|_|_ ___| |__    " "DarkYellow"
    Write-ColorLine "| |_ / _`` / __| __| |_ / _ \\ __/ __| '_ \   " "Green"
    Write-ColorLine "|  _| (_| \__ \\ |_|  _|  __/ || (__| | | |  " "Cyan"
    Write-ColorLine "|_|  \__,_|___/\__|_|  \___|\\__\___|_| |_|  " "Blue"
    Write-Color "        themes-mt3k " "White"; Write-ColorLine "v$Version" "Gray"; Write-Host ""
    $current = Get-CurrentTheme
    if (-not [string]::IsNullOrEmpty($current)) {
        $parts = $current.Split("|")
        if ($parts.Count -ge 2) {
            $curColor = Get-ThemeColor $parts[1]
            Write-Color "  Current: " "White"; Write-Color $parts[0] $curColor; Write-ColorLine " ($($parts[1]))" "Gray"
        }
    }
    $large = ($ThemeTypes | Where-Object { $_ -eq "Large-Themes" }).Count
    $small = ($ThemeTypes | Where-Object { $_ -eq "Small-Themes" }).Count
    $visual = ($ThemeTypes | Where-Object { $_ -eq "Visuals-Themes" }).Count
    Write-Color "[L]" "Red"; Write-Color "=Large($large)  " "Gray"
    Write-Color "[S]" "Green"; Write-Color "=Small($small)  " "Gray"
    Write-Color "[V]" "DarkYellow"; Write-Color "=Visual($visual)  " "Gray"
    Write-ColorLine "Total: $($Themes.Count)" "White"
    if (-not [string]::IsNullOrEmpty($script:CategoryFilter)) {
        Write-Color "  Filter: " "Yellow"; Write-ColorLine "$($script:CategoryFilter) ($($FThemes.Count) shown)" "Yellow"
    }
    Write-ColorLine "--------------------------------------------" "Gray"
}

function Show-Themes {
    $currentCat = ""; $col = 0; $colWidth = 18; $cols = 4
    for ($i = 0; $i -lt $FThemes.Count; $i++) {
        $cat = $FTypes[$i]; $num = $i + 1; $color = Get-ThemeColor $cat
        $fav = ""; if (Test-Favorite $FThemes[$i]) { $fav = "*" }
        if ($cat -ne $currentCat) {
            if ($col -ne 0) { Write-Host "" }; $col = 0; $currentCat = $cat; Write-Host ""
            switch ($cat) {
                "Large-Themes"   { Write-ColorLine "=== LARGE ================================================" "Red" }
                "Small-Themes"   { Write-ColorLine "=== SMALL ================================================" "Green" }
                "Visuals-Themes" { Write-ColorLine "=== VISUAL ===============================================" "DarkYellow" }
            }
        }
        $numStr = "[{0:D2}]" -f $num
        $dn = ($FThemes[$i] + $fav).PadRight($colWidth).Substring(0, $colWidth)
        Write-Color $numStr "Cyan"; Write-Color $dn $color; $col++
        if ($col -ge $cols) { Write-Host ""; $col = 0 }
    }
    if ($col -ne 0) { Write-Host "" }; Write-Host ""
    Write-ColorLine "=========================================================" "Gray"
    Write-Color "[x]" "Red"; Write-Color " Exit   " "White"; Write-Color "[b]" "Green"; Write-Color " Backup   " "White"
    Write-Color "[r]" "DarkYellow"; Write-Color " Restore  " "White"; Write-ColorLine "[p] Preview" "White"
    Write-Color "[f]" "Magenta"; Write-Color " Fonts  " "White"; Write-Color "[s]" "Blue"; Write-Color " Shell    " "White"
    Write-Color "[d]" "DarkMagenta"; Write-Color " Random   " "White"; Write-ColorLine "[/] Search" "White"
    Write-Color "[k]" "DarkYellow"; Write-Color " Kitty  " "White"; Write-Color "[u]" "Cyan"; Write-Color " Update   " "White"
    Write-Color "[v]" "Green"; Write-Color " Favs     " "White"; Write-ColorLine "[h] History" "White"
    Write-Color "[c]" "Green"; Write-Color " Filter " "White"; Write-Color "[w]" "Magenta"; Write-Color " Slideshow " "White"
    Write-Color "[i]" "Yellow"; Write-Color " Info    " "White"; Write-ColorLine "[+] Fav+-" "White"
}

# ──────────────────────────────────────────────────────────────
# BACKUP / RESTORE (Enhanced)
# ──────────────────────────────────────────────────────────────

function Backup-Config {
    $timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
    $backupDir = Join-Path $ScriptDir "Backup-$timestamp"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    if (Test-Path $ConfigDir) {
        Copy-Item -Path $ConfigDir -Destination $backupDir -Recurse
        Write-ColorLine "OK Backup saved to: $backupDir" "Green"
        $backups = Get-ChildItem -Path $ScriptDir -Directory -Filter "Backup-*" | Sort-Object Name -Descending
        if ($backups.Count -gt $MaxBackups) {
            for ($j = $MaxBackups; $j -lt $backups.Count; $j++) {
                Remove-Item -Recurse -Force $backups[$j].FullName
                Write-ColorLine "  Pruned: $($backups[$j].Name)" "Gray"
            }
        }
    } else { Write-ColorLine "! No config to backup" "Yellow" }
    Start-Sleep 1.5
}

function Restore-Config {
    $backups = Get-ChildItem -Path $ScriptDir -Directory -Filter "Backup-*" | Sort-Object Name -Descending
    if ($backups.Count -eq 0) { Write-ColorLine "X No backups found" "Red"; Start-Sleep 1.5; return }
    Write-Host ""; Write-ColorLine "=== AVAILABLE BACKUPS =====================================" "DarkYellow"
    for ($j = 0; $j -lt $backups.Count; $j++) {
        Write-Color "  [$($j+1)]" "Green"; Write-ColorLine " $($backups[$j].Name)" "White"
    }
    Write-Color "  [x]" "Red"; Write-ColorLine " Cancel" "White"
    Write-ColorLine "-----------------------------------------------------------" "Gray"
    Write-Host ""; Write-Color "mt3k" "Green"; Write-Color "@" "White"; Write-ColorLine "restore" "DarkYellow"
    Write-Color "> " "Red"; $choice = Read-Host
    if ($choice -match "^[xX]$") { return }
    if ($choice -match "^\d+$") {
        $bi = [int]$choice - 1
        if ($bi -ge 0 -and $bi -lt $backups.Count) {
            $sel = $backups[$bi].FullName
            if (Test-Path (Join-Path $sel "fastfetch")) {
                if (Test-Path $ConfigDir) { Remove-Item -Path $ConfigDir -Recurse -Force }
                Copy-Item -Path (Join-Path $sel "fastfetch") -Destination $ConfigDir -Recurse
                Write-ColorLine "OK Restored from: $($backups[$bi].Name)" "Green"; Start-Sleep 1; & fastfetch
            } else { Write-ColorLine "X Backup corrupted" "Red"; Start-Sleep 1.5 }
        } else { Write-ColorLine "Invalid selection" "Red"; Start-Sleep 0.5 }
    }
}

# ──────────────────────────────────────────────────────────────
# PROTOCOL PROMPT
# ──────────────────────────────────────────────────────────────

function Prompt-Protocol {
    Write-Host ""; Write-ColorLine "Choose the image rendering protocol:" "Yellow"
    Write-ColorLine "-----------------------------------------------------------" "Gray"
    Write-Color "[1]" "Green"; Write-ColorLine " auto          - Auto-detect" "White"
    Write-Color "[2]" "Green"; Write-ColorLine " kitty         - Standard Kitty protocol" "White"
    Write-Color "[3]" "Green"; Write-ColorLine " kitty-direct  - Fastest" "White"
    Write-Color "[4]" "Green"; Write-ColorLine " iterm         - iTerm2 protocol" "White"
    Write-Color "[5]" "Green"; Write-ColorLine " sixel         - Sixel graphics" "White"
    Write-Color "[6]" "Green"; Write-ColorLine " chafa         - Terminal-safe image fallback" "White"
    Write-ColorLine "-----------------------------------------------------------" "Gray"
    while ($true) {
        Write-Color "mt3k" "Green"; Write-Color "@" "White"; Write-ColorLine "protocol" "Red"
        Write-Color "> " "Red"; $choice = Read-Host
        switch ($choice) {
            "1" { $script:LogoProtocol = "auto"; return } "2" { $script:LogoProtocol = "kitty"; return }
            "3" { $script:LogoProtocol = "kitty-direct"; return } "4" { $script:LogoProtocol = "iterm"; return }
            "5" { $script:LogoProtocol = "sixel"; return } "6" { $script:LogoProtocol = "chafa"; return }
            default { Write-ColorLine "Invalid. Select 1-6." "Red" }
        }
    }
}

function Update-VisualLogoConfig {
    param([string]$ConfigFile, [string]$BaseDir)
    $content = Get-Content $ConfigFile -Raw
    $sourceMatch = [regex]::Match($content, '"source":\s*"([^"]+)"')
    $source = if ($sourceMatch.Success) { $sourceMatch.Groups[1].Value } else { "" }

    if ($LogoProtocol -eq "chafa" -and $source -and (Get-Command chafa -ErrorAction SilentlyContinue)) {
        $imagePath = if ([System.IO.Path]::IsPathRooted($source)) { $source } else { Join-Path $BaseDir $source }
        $ansiFile = Join-Path $BaseDir "logo-chafa.ansi"
        $ansiLogo = (& chafa --size 40x20 --symbols block --colors full --format symbols $imagePath) -join [Environment]::NewLine
        [System.IO.File]::WriteAllText($ansiFile, $ansiLogo, [System.Text.UTF8Encoding]::new($false))
        $escapedAnsi = $ansiFile -replace '\\', '/'
        $content = $content -replace '("logo":\s*\{[^}]*"type":\s*")[^"]*(")', "`$1raw`$2"
        $content = $content -replace '"source":\s*"[^"]*"', "`"source`": `"$escapedAnsi`""
    } else {
        $content = $content -replace '("logo":\s*\{[^}]*"type":\s*")[^"]*(")', "`$1$LogoProtocol`$2"
        $escaped = $BaseDir -replace '\\', '/'
        $content = $content -replace '"source":\s*"([^"/][^"]*)"', "`"source`": `"$escaped/`$1`""
    }
    Set-Content -Path $ConfigFile -Value $content -NoNewline
}

# ──────────────────────────────────────────────────────────────
# THEME APPLICATION (Enhanced)
# ──────────────────────────────────────────────────────────────

function Apply-Theme {
    param([int]$Index, [bool]$PreviewOnly = $false)
    $themePath = $ThemePaths[$Index]; $themeName = $Themes[$Index]; $themeType = $ThemeTypes[$Index]
    if ($PreviewOnly) { Write-Color "Previewing " "Cyan" } else { Write-Color "Applying " "Cyan" }
    Write-Color $themeName "Green"; Write-ColorLine "..." "Cyan"; Start-Sleep -Milliseconds 300
    if ($PreviewOnly) {
        $tmpConfig = Join-Path $env:TEMP "fastfetch-preview-$(Get-Random)"
        New-Item -ItemType Directory -Path $tmpConfig -Force | Out-Null
        Copy-Item -Path (Join-Path $themePath "fastfetch\*") -Destination $tmpConfig -Recurse
        $configFile = Join-Path $tmpConfig "config.jsonc"
        if ($themeType -eq "Visuals-Themes" -and (Test-Path $configFile)) {
            Update-VisualLogoConfig -ConfigFile $configFile -BaseDir $tmpConfig
        }
        Clear-Host; Write-ColorLine "=== PREVIEW: $themeName ===============================" "Cyan"
        Write-ColorLine "(Preview only - config NOT changed)" "DarkGray"; Write-Host ""
        & fastfetch --config $configFile --show-errors
        Remove-Item -Recurse -Force $tmpConfig -EA SilentlyContinue
    } else {
        if (Test-Path $ConfigDir) { Remove-Item -Path $ConfigDir -Recurse -Force }
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
        Copy-Item -Path (Join-Path $themePath "fastfetch\*") -Destination $ConfigDir -Recurse
        $configFile = Join-Path $ConfigDir "config.jsonc"
        if ($themeType -eq "Visuals-Themes" -and (Test-Path $configFile)) {
            Update-VisualLogoConfig -ConfigFile $configFile -BaseDir $ConfigDir
        }
        Save-CurrentTheme $themeName $themeType
        Add-ToHistory $themeName $themeType
        Clear-Host; Write-Color "Running fastfetch with " "Cyan"; Write-Color $themeName "Green"; Write-ColorLine "..." "Cyan"; Write-Host ""
        & fastfetch --show-errors
    }
}

# ──────────────────────────────────────────────────────────────
# SEARCH / RANDOM / PREVIEW (Enhanced)
# ──────────────────────────────────────────────────────────────

function Search-Themes {
    Write-Host ""; Write-Color "Search theme: " "Yellow"; $query = Read-Host
    if ([string]::IsNullOrWhiteSpace($query)) { Write-ColorLine "Empty search" "Red"; Start-Sleep -Milliseconds 500; return }
    $found = $false; Write-Host ""; Write-ColorLine "Results for '$query':" "Cyan"
    Write-ColorLine "-----------------------------------------------------------" "Gray"
    for ($i = 0; $i -lt $Themes.Count; $i++) {
        if ($Themes[$i] -match [regex]::Escape($query)) {
            $color = Get-ThemeColor $ThemeTypes[$i]
            Write-Color "  [$($i+1)]" "Green"; Write-Color " $($Themes[$i])" $color; Write-ColorLine " ($($ThemeTypes[$i]))" "Gray"
            $found = $true
        }
    }
    if (-not $found) { Write-ColorLine "  No themes found matching '$query'" "Red"; Start-Sleep 1.5; return }
    Write-ColorLine "-----------------------------------------------------------" "Gray"
    Write-Color "mt3k" "Green"; Write-Color "@" "White"; Write-ColorLine "search" "Yellow"
    Write-Color "> " "Red"; $choice = Read-Host
    if ($choice -match "^\d+$") {
        $idx = [int]$choice - 1
        if ($idx -ge 0 -and $idx -lt $Themes.Count) {
            if ($ThemeTypes[$idx] -eq "Visuals-Themes") { Prompt-Protocol }
            Apply-Theme -Index $idx; Write-Host ""; Write-ColorLine "Press enter to continue..." "Green"; Read-Host | Out-Null
        } else { Write-ColorLine "Invalid selection" "Red"; Start-Sleep -Milliseconds 500 }
    }
}

function Random-Theme {
    Write-Host ""; Write-ColorLine "=== RANDOM THEME ==========================================" "Magenta"
    Write-Color "[1]" "Green"; Write-ColorLine " Random from ALL" "White"
    Write-Color "[2]" "Red"; Write-ColorLine " Random Large" "White"
    Write-Color "[3]" "Green"; Write-ColorLine " Random Small" "White"
    Write-Color "[4]" "DarkYellow"; Write-ColorLine " Random Visual" "White"
    Write-Color "[x]" "Red"; Write-ColorLine " Cancel" "White"
    Write-ColorLine "-----------------------------------------------------------" "Gray"
    Write-Host ""; Write-Color "mt3k" "Green"; Write-Color "@" "White"; Write-ColorLine "random" "Magenta"
    Write-Color "> " "Red"; $choice = Read-Host
    $pool = @(); $pidx = @()
    switch ($choice) {
        "1" { for ($i=0; $i -lt $Themes.Count; $i++) { $pool += $Themes[$i]; $pidx += $i } }
        "2" { for ($i=0; $i -lt $Themes.Count; $i++) { if ($ThemeTypes[$i] -eq "Large-Themes") { $pool += $Themes[$i]; $pidx += $i } } }
        "3" { for ($i=0; $i -lt $Themes.Count; $i++) { if ($ThemeTypes[$i] -eq "Small-Themes") { $pool += $Themes[$i]; $pidx += $i } } }
        "4" { for ($i=0; $i -lt $Themes.Count; $i++) { if ($ThemeTypes[$i] -eq "Visuals-Themes") { $pool += $Themes[$i]; $pidx += $i } } }
        { $_ -match "^[xX]$" } { return }
        default { Write-ColorLine "Invalid choice" "Red"; Start-Sleep 0.5; return }
    }
    if ($pool.Count -eq 0) { Write-ColorLine "No themes in that category" "Red"; Start-Sleep 1; return }
    $ri = Get-Random -Minimum 0 -Maximum $pool.Count; $realIdx = $pidx[$ri]
    Write-Host ""; Write-Color "Random pick: " "Magenta"; Write-Color $Themes[$realIdx] "White"; Write-ColorLine " ($($ThemeTypes[$realIdx]))" "Gray"
    if ($ThemeTypes[$realIdx] -eq "Visuals-Themes") { Prompt-Protocol }
    Apply-Theme -Index $realIdx; Write-Host ""; Write-ColorLine "Press enter to continue..." "Green"; Read-Host | Out-Null
}

function Preview-Theme {
    Write-Host ""; Write-Color "Enter theme number to preview: " "Cyan"; $choice = Read-Host
    if ($choice -match "^\d+$") {
        $idx = [int]$choice - 1
        if ($idx -ge 0 -and $idx -lt $FThemes.Count) {
            $realIdx = $FIdx[$idx]
            if ($ThemeTypes[$realIdx] -eq "Visuals-Themes") { Prompt-Protocol }
            Apply-Theme -Index $realIdx -PreviewOnly $true; Write-Host ""; Write-ColorLine "Press enter to continue..." "Green"; Read-Host | Out-Null
        } else { Write-ColorLine "Invalid selection" "Red"; Start-Sleep -Milliseconds 500 }
    } else { Write-ColorLine "Invalid number" "Red"; Start-Sleep -Milliseconds 500 }
}

# ──────────────────────────────────────────────────────────────
# NEW FEATURES
# ──────────────────────────────────────────────────────────────

function Favorites-Menu {
    Write-Host ""; Write-ColorLine "=== FAVORITES * ===========================================" "Green"
    if (-not (Test-Path $FavoritesFile) -or (Get-Content $FavoritesFile -EA SilentlyContinue | Where-Object { $_ -ne "" }).Count -eq 0) {
        Write-ColorLine "No favorites yet. Use [+] to add themes." "Gray"
        Write-ColorLine "Press enter to continue..." "Green"; Read-Host | Out-Null; return
    }
    $favNames = @(); $favIndices = @(); $fi = 1
    Get-Content $FavoritesFile | Where-Object { $_ -ne "" } | ForEach-Object {
        $fn = $_
        for ($i = 0; $i -lt $Themes.Count; $i++) {
            if ($Themes[$i] -eq $fn) {
                $color = Get-ThemeColor $ThemeTypes[$i]
                Write-Color "  [$fi]" "Green"; Write-Color " $fn" $color; Write-ColorLine " ($($ThemeTypes[$i]))" "Gray"
                $favNames += $fn; $favIndices += $i; $fi++; break
            }
        }
    }
    if ($favNames.Count -eq 0) { Write-ColorLine "No matching favorites." "Gray"; Write-ColorLine "Press enter..." "Green"; Read-Host | Out-Null; return }
    Write-ColorLine "-----------------------------------------------------------" "Gray"
    Write-Color "mt3k" "Green"; Write-Color "@" "White"; Write-ColorLine "favs" "Green"
    Write-Color "> " "Red"; $choice = Read-Host
    if ($choice -match "^\d+$") {
        $idx = [int]$choice - 1
        if ($idx -ge 0 -and $idx -lt $favNames.Count) {
            $realIdx = $favIndices[$idx]
            if ($ThemeTypes[$realIdx] -eq "Visuals-Themes") { Prompt-Protocol }
            Apply-Theme -Index $realIdx; Write-Host ""; Write-ColorLine "Press enter to continue..." "Green"; Read-Host | Out-Null
        } else { Write-ColorLine "Invalid" "Red"; Start-Sleep 0.5 }
    }
}

function Add-FavoritePrompt {
    Write-Color "Enter theme number to toggle favorite: " "Green"; $choice = Read-Host
    if ($choice -match "^\d+$") {
        $idx = [int]$choice - 1
        if ($idx -ge 0 -and $idx -lt $FThemes.Count) { Toggle-Favorite $FThemes[$idx] }
        else { Write-ColorLine "Invalid" "Red"; Start-Sleep 0.5 }
    } else { Write-ColorLine "Invalid" "Red"; Start-Sleep 0.5 }
}

function Show-History {
    Write-Host ""; Write-ColorLine "=== THEME HISTORY =========================================" "Magenta"
    if (-not (Test-Path $HistoryFile) -or (Get-Content $HistoryFile -EA SilentlyContinue).Count -eq 0) {
        Write-ColorLine "No history yet." "Gray"; Write-ColorLine "Press enter..." "Green"; Read-Host | Out-Null; return
    }
    $lines = Get-Content $HistoryFile; $start = [Math]::Max(0, $lines.Count - 10); Write-Host ""
    for ($j = $lines.Count - 1; $j -ge $start; $j--) {
        $parts = $lines[$j].Split("|")
        if ($parts.Count -ge 3) {
            $color = Get-ThemeColor $parts[2]
            Write-Color "  [$($parts[0])]" "Gray"; Write-Color " $($parts[1])" $color; Write-ColorLine " ($($parts[2]))" "Gray"
        }
    }
    Write-ColorLine "-----------------------------------------------------------" "Gray"
    Write-ColorLine "Press enter to continue..." "Green"; Read-Host | Out-Null
}

function Update-Repo {
    Write-Host ""; Write-ColorLine "=== UPDATE THEMES =========================================" "Cyan"
    if (-not (Test-Path (Join-Path $ScriptDir ".git"))) {
        Write-ColorLine "! Not a git repository. Clone from GitHub to enable updates." "Yellow"
        Write-ColorLine "Press enter..." "Green"; Read-Host | Out-Null; return
    }
    if (-not (Get-Command git -EA SilentlyContinue)) { Write-ColorLine "X git not installed" "Red"; Start-Sleep 1.5; return }
    Write-ColorLine "Checking for updates..." "Cyan"
    Push-Location $ScriptDir; git fetch 2>$null
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    $behind = git rev-list "HEAD..origin/$branch" --count 2>$null
    if ([int]$behind -gt 0) {
        Write-ColorLine "$behind new commit(s) available!" "Green"
        git log --oneline "HEAD..origin/$branch" 2>$null | Select-Object -First 5
        Write-Color "Pull updates? [y/N]: " "Green"; $yn = Read-Host
        if ($yn -match "^[yY]$") { git pull; Write-ColorLine "OK Updated! Rescanning..." "Green"; Scan-Themes; Start-Sleep 1 }
    } else { Write-ColorLine "OK Already up to date!" "Green" }
    Pop-Location; Write-ColorLine "Press enter to continue..." "Green"; Read-Host | Out-Null
}

function Theme-Info {
    Write-Color "Enter theme number for info: " "Yellow"; $choice = Read-Host
    if ($choice -match "^\d+$") {
        $idx = [int]$choice - 1
        if ($idx -ge 0 -and $idx -lt $FThemes.Count) {
            $ri = $FIdx[$idx]; $name = $Themes[$ri]; $path = $ThemePaths[$ri]; $type = $ThemeTypes[$ri]
            $color = Get-ThemeColor $type; $fav = "No"; if (Test-Favorite $name) { $fav = "Yes *" }
            Write-Host ""; Write-ColorLine "=== THEME INFO ============================================" "Cyan"
            Write-Color "  Name:     " "White"; Write-ColorLine $name $color
            Write-Color "  Category: " "White"; Write-ColorLine $type $color
            Write-Color "  Path:     " "White"; Write-ColorLine $path "Gray"
            Write-Color "  Favorite: " "White"; Write-ColorLine $fav "Green"
            $cf = Join-Path $path "fastfetch\config.jsonc"
            if (-not (Test-Path $cf)) { $cf = Join-Path $path "fastfetch\config.json" }
            if (Test-Path $cf) {
                $sz = (Get-Item $cf).Length; Write-Color "  Config:   " "White"; Write-ColorLine "$sz bytes" "Gray"
                $content = Get-Content $cf -Raw; $mods = ([regex]::Matches($content, '"type"')).Count
                Write-Color "  Modules:  " "White"; Write-ColorLine "~$mods detected" "Gray"
                $imgs = Get-ChildItem (Join-Path $path "fastfetch") -Include "*.png","*.jpg","*.gif","*.webp","*.svg" -EA SilentlyContinue
                if ($imgs) { Write-Color "  Images:   " "White"; Write-ColorLine "$($imgs.Count) image(s)" "DarkYellow" }
            }
            Write-ColorLine "===========================================================" "Cyan"
            Write-ColorLine "Press enter to continue..." "Green"; Read-Host | Out-Null
        } else { Write-ColorLine "Invalid" "Red"; Start-Sleep 0.5 }
    } else { Write-ColorLine "Invalid" "Red"; Start-Sleep 0.5 }
}

function Filter-Menu {
    Write-Host ""; Write-ColorLine "=== FILTER BY CATEGORY ====================================" "Green"
    Write-Color "[0]" "Green"; Write-ColorLine " Show ALL themes" "White"
    Write-Color "[1]" "Red"; Write-ColorLine " Large themes only" "White"
    Write-Color "[2]" "Green"; Write-ColorLine " Small themes only" "White"
    Write-Color "[3]" "DarkYellow"; Write-ColorLine " Visual themes only" "White"
    Write-ColorLine "-----------------------------------------------------------" "Gray"
    Write-Color "mt3k" "Green"; Write-Color "@" "White"; Write-ColorLine "filter" "Green"
    Write-Color "> " "Red"; $choice = Read-Host
    switch ($choice) {
        "0" { $script:CategoryFilter = "" } "1" { $script:CategoryFilter = "Large-Themes" }
        "2" { $script:CategoryFilter = "Small-Themes" } "3" { $script:CategoryFilter = "Visuals-Themes" }
        default { Write-ColorLine "Invalid" "Red"; Start-Sleep 0.5; return }
    }
    Apply-Filter; Write-ColorLine "OK Filter updated" "Green"; Start-Sleep 0.5
}

function Start-Slideshow {
    Write-Color "Slideshow delay in seconds [3]: " "Magenta"; $delay = Read-Host
    if ([string]::IsNullOrEmpty($delay)) { $delay = 3 }
    if ([string]::IsNullOrEmpty($script:LogoProtocol)) { $script:LogoProtocol = "auto" }
    Write-ColorLine "Starting slideshow... Press Ctrl+C to stop" "Magenta"; Start-Sleep 1
    for ($i = 0; $i -lt $FThemes.Count; $i++) {
        $ri = $FIdx[$i]; Clear-Host
        Write-ColorLine "=== SLIDESHOW [$($i+1)/$($FThemes.Count)] =============================" "Magenta"
        Write-Color "Theme: " "Cyan"; Write-Color $FThemes[$i] "Green"; Write-ColorLine " ($($FTypes[$i]))" "Gray"
        Write-ColorLine "(Press Ctrl+C to stop)" "DarkGray"; Write-Host ""
        Apply-Theme -Index $ri -PreviewOnly $true
        Start-Sleep -Seconds $delay
    }
    Write-ColorLine "Slideshow complete! Press enter..." "Green"; Read-Host | Out-Null
}

function Show-Help {
    Write-Color "fastfetch-themes-mt3k " "Cyan"; Write-ColorLine "v$Version" "Gray"
    Write-ColorLine "Auto-detecting fastfetch theme selector" "White"; Write-Host ""
    Write-ColorLine "Usage:" "Green"
    Write-ColorLine "  .\fastfetch-themes-mt3k.ps1                   # Interactive" "White"
    Write-ColorLine "  .\fastfetch-themes-mt3k.ps1 -Apply NAME       # Apply theme" "White"
    Write-ColorLine "  .\fastfetch-themes-mt3k.ps1 -Preview NAME     # Preview theme" "White"
    Write-ColorLine "  .\fastfetch-themes-mt3k.ps1 -Random [CAT]     # Random" "White"
    Write-ColorLine "  .\fastfetch-themes-mt3k.ps1 -List [CAT]       # List themes" "White"
    Write-ColorLine "  .\fastfetch-themes-mt3k.ps1 -Search QUERY     # Search" "White"
    Write-ColorLine "  .\fastfetch-themes-mt3k.ps1 -Update           # Git update" "White"
    Write-ColorLine "  .\fastfetch-themes-mt3k.ps1 -ShowVersion      # Version" "White"
    Write-ColorLine "  .\fastfetch-themes-mt3k.ps1 -ShowHelp         # This help" "White"
}

# ──────────────────────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────────────────────

function Main {
    # CLI argument handling
    $cliArgs = $script:MyInvocation.UnboundArguments
    if ($args.Count -gt 0 -or $cliArgs.Count -gt 0) {
        $allArgs = if ($args.Count -gt 0) { $args } else { $cliArgs }
        $cmd = $allArgs[0]
        switch -Regex ($cmd) {
            "^-?(ShowHelp|help|h)$" { Show-Help; return }
            "^-?(ShowVersion|version|V)$" { Write-Host "fastfetch-themes-mt3k v$Version"; return }
            "^-?(List|list|l)$" {
                Scan-Themes
                if ($allArgs.Count -gt 1) {
                    switch ($allArgs[1]) { "large" { $script:CategoryFilter = "Large-Themes" } "small" { $script:CategoryFilter = "Small-Themes" } "visual" { $script:CategoryFilter = "Visuals-Themes" } }
                    Apply-Filter
                }
                $FThemes | ForEach-Object { $i = [array]::IndexOf($FThemes, $_); Write-Host "$_ ($($FTypes[$i]))" }; return
            }
            "^-?(Apply|apply|a)$" {
                Check-Fastfetch; Init-DataDir; Scan-Themes
                $idx = Find-ThemeByName $allArgs[1]
                if ($idx -ge 0) {
                    if ($ThemeTypes[$idx] -eq "Visuals-Themes") { $script:LogoProtocol = if ($allArgs.Count -gt 2) { $allArgs[2] } else { "auto" } }
                    Apply-Theme -Index $idx
                } else { Write-Host "Theme '$($allArgs[1])' not found" }; return
            }
            "^-?(Preview|preview)$" {
                Check-Fastfetch; Init-DataDir; Scan-Themes
                $idx = Find-ThemeByName $allArgs[1]
                if ($idx -ge 0) {
                    if ($ThemeTypes[$idx] -eq "Visuals-Themes") { $script:LogoProtocol = if ($allArgs.Count -gt 2) { $allArgs[2] } else { "auto" } }
                    Apply-Theme -Index $idx -PreviewOnly $true
                } else { Write-Host "Theme '$($allArgs[1])' not found" }; return
            }
            "^-?(Random|random)$" {
                Check-Fastfetch; Init-DataDir; Scan-Themes
                if ($allArgs.Count -gt 1) {
                    switch ($allArgs[1]) { "large" { $script:CategoryFilter = "Large-Themes" } "small" { $script:CategoryFilter = "Small-Themes" } "visual" { $script:CategoryFilter = "Visuals-Themes" } }
                    Apply-Filter
                }
                $ri = Get-Random -Minimum 0 -Maximum $FThemes.Count; $realIdx = $FIdx[$ri]
                if ($ThemeTypes[$realIdx] -eq "Visuals-Themes") { $script:LogoProtocol = "auto" }
                Write-Host "Random: $($Themes[$realIdx]) ($($ThemeTypes[$realIdx]))"; Apply-Theme -Index $realIdx; return
            }
            "^-?(Search|search)$" { Scan-Themes; $Themes | Where-Object { $_ -match [regex]::Escape($allArgs[1]) } | ForEach-Object { Write-Host $_ }; return }
            "^-?(Update|update)$" { Update-Repo; return }
        }
    }

    Check-Fastfetch; Init-DataDir; Scan-Themes
    if ($Themes.Count -eq 0) { Write-ColorLine "No themes found!" "Red"; exit 1 }

    while ($true) {
        Show-Banner; Show-Themes; Write-Host ""
        Write-Color "mt3k" "Green"; Write-Color "@" "White"; Write-ColorLine "themes" "Red"
        Write-Color "> " "Red"; $choice = Read-Host
        switch -Regex ($choice) {
            "^[xXqQ]$" { Clear-Host; Write-ColorLine "Goodbye!" "Red"; exit 0 }
            "^[bB]$" { Backup-Config } "^[rR]$" { Restore-Config }
            "^[fF]$" { Install-NerdFonts } "^[sS]$" { Setup-Shell }
            "^[dD]$" { Random-Theme } "^[pP]$" { Preview-Theme }
            "^[kK]$" { Install-Kitty } "^[/\\]$" { Search-Themes }
            "^[uU]$" { Update-Repo } "^[vV]$" { Favorites-Menu }
            "^[hH]$" { Show-History } "^[cC]$" { Filter-Menu }
            "^[wW]$" { Start-Slideshow } "^[iI]$" { Theme-Info }
            "^\+$" { Add-FavoritePrompt }
            "^\d+$" {
                $idx = [int]$choice - 1
                if ($idx -ge 0 -and $idx -lt $FThemes.Count) {
                    $realIdx = $FIdx[$idx]
                    if ($ThemeTypes[$realIdx] -eq "Visuals-Themes") { Prompt-Protocol }
                    Apply-Theme -Index $realIdx
                    Write-Host ""; Write-ColorLine "Press enter to continue..." "Green"; Read-Host | Out-Null
                } else { Write-ColorLine "Invalid selection" "Red"; Start-Sleep -Milliseconds 500 }
            }
            default { Write-ColorLine "Invalid selection" "Red"; Start-Sleep -Milliseconds 500 }
        }
    }
}

Main @args
