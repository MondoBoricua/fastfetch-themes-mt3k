# fastfetch-themes-mt3k.ps1 - Auto-detecting fastfetch theme selector for Windows
# Detects themes automatically from Large-Themes, Small-Themes, and Visuals-Themes

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = "$env:USERPROFILE\.config\fastfetch"
$Version = "2.0.0"

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

# ──────────────────────────────────────────────────────────────
# DEPENDENCY CHECKS
# ──────────────────────────────────────────────────────────────

function Check-Fastfetch {
    if (-not (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-ColorLine "=== fastfetch NOT FOUND ===================================" "Red"
        Write-ColorLine "fastfetch is required but not installed." "Yellow"
        Write-Host ""

        $installer = $null
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            $installer = "winget install Fastfetch-cli.Fastfetch"
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            $installer = "choco install fastfetch"
        } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            $installer = "scoop install fastfetch"
        }

        if ($installer) {
            Write-ColorLine "Detected package manager. Install with:" "Green"
            Write-ColorLine "  $installer" "Cyan"
            Write-Host ""
            Write-Color "Install now? [y/N]: " "Green"
            $yn = Read-Host

            if ($yn -match "^[yY]$") {
                Write-ColorLine "Running: $installer" "Cyan"
                Invoke-Expression $installer

                if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
                    Write-ColorLine "OK fastfetch installed successfully!" "Green"
                    Start-Sleep -Seconds 1
                    return
                } else {
                    Write-ColorLine "X Installation failed. Please install manually." "Red"
                    exit 1
                }
            } else {
                Write-ColorLine "Skipped. Please install fastfetch manually." "Yellow"
                exit 1
            }
        } else {
            Write-ColorLine "Could not detect package manager." "Red"
            Write-ColorLine "Install fastfetch manually:" "Yellow"
            Write-ColorLine "  winget install Fastfetch-cli.Fastfetch" "Cyan"
            Write-ColorLine "  https://github.com/fastfetch-cli/fastfetch" "Cyan"
            exit 1
        }
    }
}

# ──────────────────────────────────────────────────────────────
# NERD FONTS INSTALLER
# ──────────────────────────────────────────────────────────────

function Install-NerdFonts {
    Write-Host ""
    Write-ColorLine "=== NERD FONTS INSTALLER ==================================" "Magenta"
    Write-ColorLine "Nerd Fonts add icons to your terminal themes." "White"
    Write-ColorLine "Fonts will be installed to your system fonts folder." "Gray"
    Write-Host ""
    Write-Color "[1]" "Green"; Write-ColorLine " JetBrainsMono   - Clean, modern (recommended)" "Gray"
    Write-Color "[2]" "Green"; Write-ColorLine " Meslo           - Classic, Powerlevel10k default" "Gray"
    Write-Color "[3]" "Green"; Write-ColorLine " FiraCode        - Popular ligature font" "Gray"
    Write-Color "[4]" "Green"; Write-ColorLine " Hack            - Minimal and sharp" "Gray"
    Write-Color "[5]" "Green"; Write-ColorLine " CascadiaCode    - Microsoft's modern font" "Gray"
    Write-Color "[6]" "Green"; Write-ColorLine " UbuntuMono      - Ubuntu's default mono" "Gray"
    Write-Color "[7]" "Green"; Write-ColorLine " SourceCodePro   - Adobe's coding font" "Gray"
    Write-Color "[a]" "Green"; Write-ColorLine " ALL of the above - Install all 7 fonts" "Gray"
    Write-Color "[x]" "Red"; Write-ColorLine " Cancel" "White"
    Write-ColorLine "-----------------------------------------------------------" "Gray"

    Write-Host ""
    Write-Color "mt3k" "Green"
    Write-Color "@" "White"
    Write-ColorLine "fonts" "Magenta"
    Write-Color "> " "Red"
    $choice = Read-Host

    $fonts = @()
    switch ($choice) {
        "1" { $fonts = @("JetBrainsMono") }
        "2" { $fonts = @("Meslo") }
        "3" { $fonts = @("FiraCode") }
        "4" { $fonts = @("Hack") }
        "5" { $fonts = @("CascadiaCode") }
        "6" { $fonts = @("UbuntuMono") }
        "7" { $fonts = @("SourceCodePro") }
        { $_ -match "^[aA]$" } { $fonts = @("JetBrainsMono", "Meslo", "FiraCode", "Hack", "CascadiaCode", "UbuntuMono", "SourceCodePro") }
        { $_ -match "^[xX]$" } { return }
        default { Write-ColorLine "Invalid choice" "Red"; Start-Sleep -Seconds 1; return }
    }

    $tmpDir = Join-Path $env:TEMP "nerd-fonts-install"
    if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    $fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    if (-not (Test-Path $fontDir)) { New-Item -ItemType Directory -Path $fontDir -Force | Out-Null }

    $baseUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
    $success = 0
    $fail = 0

    foreach ($fontName in $fonts) {
        $zipUrl = "$baseUrl/$fontName.zip"
        $zipFile = Join-Path $tmpDir "$fontName.zip"
        $extractDir = Join-Path $tmpDir $fontName

        Write-Color "Downloading " "Cyan"
        Write-ColorLine "$fontName Nerd Font..." "White"

        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile -UseBasicParsing -ErrorAction Stop

            New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
            Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force

            # Install fonts - copy to user fonts directory
            $fontFiles = Get-ChildItem -Path $extractDir -Recurse -Include "*.ttf", "*.otf" | Where-Object { $_.Name -notmatch "Windows" }

            foreach ($ff in $fontFiles) {
                Copy-Item -Path $ff.FullName -Destination $fontDir -Force
                # Register the font
                $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
                $fontRegName = [System.IO.Path]::GetFileNameWithoutExtension($ff.Name) + " (TrueType)"
                New-ItemProperty -Path $regPath -Name $fontRegName -Value $ff.FullName -PropertyType String -Force | Out-Null
            }

            Write-ColorLine "  OK $fontName installed ($($fontFiles.Count) files)!" "Green"
            $success++
        } catch {
            Write-ColorLine "  X Failed to install $fontName" "Red"
            $fail++
        }
    }

    # Cleanup
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue

    Write-Host ""
    Write-ColorLine "=== DONE ===================================================" "Green"
    Write-ColorLine "  OK $success font(s) installed" "Green"
    if ($fail -gt 0) { Write-ColorLine "  X $fail font(s) failed" "Red" }
    Write-ColorLine "  ! Remember to set the Nerd Font in your terminal settings!" "Yellow"
    Write-ColorLine "  (You may need to restart your terminal for fonts to appear)" "Gray"
    Write-Host ""
    Write-ColorLine "Press enter to continue..." "Green"
    Read-Host | Out-Null
}

# ──────────────────────────────────────────────────────────────
# KITTY TERMINAL INSTALLER
# ──────────────────────────────────────────────────────────────

function Install-Kitty {
    Write-Host ""
    Write-ColorLine "=== KITTY TERMINAL INSTALLER ==============================" "DarkYellow"
    Write-ColorLine "Kitty is a GPU-accelerated terminal with image support." "White"
    Write-ColorLine "Required for Visual themes with kitty/kitty-direct protocol." "Gray"
    Write-Host ""

    # Check if already installed
    if (Get-Command kitty -ErrorAction SilentlyContinue) {
        $kittyVer = & kitty --version 2>$null | Select-Object -First 1
        Write-ColorLine "OK Kitty is already installed: $kittyVer" "Green"
        Write-Host ""
        Write-ColorLine "Reinstall/update anyway?" "Yellow"
        Write-Color "[y/N]: " "White"
        $yn = Read-Host
        if ($yn -notmatch "^[yY]$") { return }
    }

    Write-Color "[1]" "Green"; Write-ColorLine " winget       - Windows Package Manager (recommended)" "Gray"
    Write-Color "[2]" "Green"; Write-ColorLine " scoop        - Scoop package manager" "Gray"
    Write-Color "[3]" "Green"; Write-ColorLine " choco        - Chocolatey package manager" "Gray"
    Write-Color "[4]" "Green"; Write-ColorLine " GitHub       - Download latest release from GitHub" "Gray"
    Write-Color "[x]" "Red"; Write-ColorLine " Cancel" "White"
    Write-ColorLine "-----------------------------------------------------------" "Gray"

    Write-Host ""
    Write-Color "mt3k" "Green"
    Write-Color "@" "White"
    Write-ColorLine "kitty" "DarkYellow"
    Write-Color "> " "Red"
    $choice = Read-Host

    switch ($choice) {
        "1" {
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                Write-ColorLine "X winget is not available on this system." "Red"
                Write-ColorLine "Install it from the Microsoft Store (App Installer)." "Yellow"
                Start-Sleep -Seconds 2
                return
            }
            Write-ColorLine "Installing Kitty via winget..." "Cyan"
            winget install --id kovidgoyal.kitty --accept-source-agreements --accept-package-agreements
            if (Get-Command kitty -ErrorAction SilentlyContinue) {
                Write-ColorLine "OK Kitty installed successfully!" "Green"
            } else {
                Write-ColorLine "X Installation may have failed. Check above." "Red"
            }
        }
        "2" {
            if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                Write-ColorLine "X scoop is not installed." "Red"
                Write-ColorLine "Install scoop from: https://scoop.sh" "Yellow"
                Start-Sleep -Seconds 2
                return
            }
            Write-ColorLine "Installing Kitty via scoop..." "Cyan"
            scoop install kitty
            if (Get-Command kitty -ErrorAction SilentlyContinue) {
                Write-ColorLine "OK Kitty installed successfully!" "Green"
            } else {
                Write-ColorLine "X Installation may have failed. Check above." "Red"
            }
        }
        "3" {
            if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                Write-ColorLine "X Chocolatey is not installed." "Red"
                Write-ColorLine "Install from: https://chocolatey.org/install" "Yellow"
                Start-Sleep -Seconds 2
                return
            }
            Write-ColorLine "Installing Kitty via Chocolatey..." "Cyan"
            choco install kitty -y
            if (Get-Command kitty -ErrorAction SilentlyContinue) {
                Write-ColorLine "OK Kitty installed successfully!" "Green"
            } else {
                Write-ColorLine "X Installation may have failed. Check above." "Red"
            }
        }
        "4" {
            Write-ColorLine "Downloading latest Kitty from GitHub..." "Cyan"
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $releaseUrl = "https://api.github.com/repos/kovidgoyal/kitty/releases/latest"
                $release = Invoke-RestMethod -Uri $releaseUrl -UseBasicParsing
                $asset = $release.assets | Where-Object { $_.name -match "kitty.*\.exe$" -or $_.name -match "kitty.*windows.*\.zip$" } | Select-Object -First 1

                if ($asset) {
                    $downloadPath = Join-Path $env:TEMP $asset.name
                    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $downloadPath -UseBasicParsing
                    Write-ColorLine "Downloaded: $($asset.name)" "Green"
                    Write-ColorLine "Saved to: $downloadPath" "Gray"
                    Write-ColorLine "Please install/extract manually from the downloaded file." "Yellow"
                } else {
                    Write-ColorLine "Could not find Windows release. Visit:" "Yellow"
                    Write-ColorLine "  https://github.com/kovidgoyal/kitty/releases" "Cyan"
                }
            } catch {
                Write-ColorLine "X Failed to download from GitHub." "Red"
                Write-ColorLine "  Visit: https://github.com/kovidgoyal/kitty/releases" "Cyan"
            }
        }
        { $_ -match "^[xX]$" } { return }
        default { Write-ColorLine "Invalid choice" "Red"; Start-Sleep -Seconds 1; return }
    }

    Write-Host ""
    Write-ColorLine "Press enter to continue..." "Green"
    Read-Host | Out-Null
}

# ──────────────────────────────────────────────────────────────
# SHELL AUTO-START SETUP
# ──────────────────────────────────────────────────────────────

function Setup-Shell {
    Write-Host ""
    Write-ColorLine "=== SHELL AUTO-START SETUP ================================" "Blue"
    Write-ColorLine "This adds fastfetch to run when you open a new terminal." "White"
    Write-Host ""

    $marker = "# fastfetch-themes-mt3k auto-start"
    $idx = 1
    $shellOptions = @()

    # PowerShell profile
    $psProfile = $PROFILE.CurrentUserCurrentHost
    Write-Color "[$idx]" "Green"; Write-ColorLine " PowerShell  ($psProfile)" "Gray"
    $shellOptions += @{ Name = "PowerShell"; File = $psProfile }
    $idx++

    # Check for Git Bash
    $gitBashRc = "$env:USERPROFILE\.bashrc"
    Write-Color "[$idx]" "Green"; Write-ColorLine " Git Bash    ($gitBashRc)" "Gray"
    $shellOptions += @{ Name = "GitBash"; File = $gitBashRc }
    $idx++

    Write-Color "[x]" "Red"; Write-ColorLine " Cancel" "White"
    Write-ColorLine "-----------------------------------------------------------" "Gray"

    Write-Host ""
    Write-Color "mt3k" "Green"
    Write-Color "@" "White"
    Write-ColorLine "shell" "Blue"
    Write-Color "> " "Red"
    $choice = Read-Host

    if ($choice -match "^[xX]$") { return }

    if ($choice -notmatch "^\d+$" -or [int]$choice -lt 1 -or [int]$choice -gt $shellOptions.Count) {
        Write-ColorLine "Invalid choice" "Red"
        Start-Sleep -Seconds 1
        return
    }

    $selected = $shellOptions[[int]$choice - 1]
    $rcFile = $selected.File
    $shellName = $selected.Name

    # Check if already configured
    if ((Test-Path $rcFile) -and (Get-Content $rcFile -Raw -ErrorAction SilentlyContinue) -match [regex]::Escape($marker)) {
        Write-Host ""
        Write-ColorLine "! fastfetch auto-start is already configured in $rcFile" "Yellow"
        Write-Color "Remove it? [y/N]: " "Yellow"
        $yn = Read-Host

        if ($yn -match "^[yY]$") {
            $content = Get-Content $rcFile
            $newContent = @()
            $skip = $false
            foreach ($line in $content) {
                if ($line -match [regex]::Escape($marker)) {
                    $skip = $true
                    continue
                }
                if ($skip) {
                    # Skip until we find the end of the block
                    if ($shellName -eq "PowerShell" -and $line -match "^\}") {
                        $skip = $false
                        continue
                    }
                    if ($shellName -eq "GitBash" -and $line -match "^fi$") {
                        $skip = $false
                        continue
                    }
                    continue
                }
                $newContent += $line
            }
            Set-Content -Path $rcFile -Value ($newContent -join "`n")
            Write-ColorLine "OK Removed fastfetch auto-start from $rcFile" "Green"
        }
        Start-Sleep -Seconds 1.5
        return
    }

    # Create directory if needed
    $rcDir = Split-Path -Parent $rcFile
    if (-not (Test-Path $rcDir)) {
        New-Item -ItemType Directory -Path $rcDir -Force | Out-Null
    }

    if ($shellName -eq "PowerShell") {
        # Check if profile exists
        if (-not (Test-Path $rcFile)) {
            New-Item -ItemType File -Path $rcFile -Force | Out-Null
        }
        $block = @"

$marker
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch
}
"@
        Add-Content -Path $rcFile -Value $block
    } else {
        # Git Bash
        if (-not (Test-Path $rcFile)) {
            New-Item -ItemType File -Path $rcFile -Force | Out-Null
        }
        $block = @"

$marker
if command -v fastfetch &>/dev/null; then
    fastfetch
fi
"@
        Add-Content -Path $rcFile -Value $block
    }

    Write-Host ""
    Write-ColorLine "OK fastfetch will now run when you open a new $shellName terminal!" "Green"
    Write-ColorLine "  Added to: $rcFile" "Gray"
    Write-ColorLine "  (Run this option again to remove it)" "DarkGray"
    Start-Sleep -Seconds 2
}

# ──────────────────────────────────────────────────────────────
# THEME SCANNING
# ──────────────────────────────────────────────────────────────

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

# ──────────────────────────────────────────────────────────────
# UI COMPONENTS
# ──────────────────────────────────────────────────────────────

function Show-Banner {
    Clear-Host
    Write-ColorLine "  __           _    __     _       _       " "Red"
    Write-ColorLine " / _| __ _ ___| |_ / _| __|_|_ ___| |__    " "DarkYellow"
    Write-ColorLine "| |_ / _`` / __| __| |_ / _ \\ __/ __| '_ \   " "Green"
    Write-ColorLine "|  _| (_| \__ \\ |_|  _|  __/ || (__| | | |  " "Cyan"
    Write-ColorLine "|_|  \__,_|___/\__|_|  \___|\\__\___|_| |_|  " "Blue"
    Write-Color "        themes-mt3k " "White"
    Write-ColorLine "v$Version" "Gray"
    Write-Host ""

    # Count themes per category
    $large = ($ThemeTypes | Where-Object { $_ -eq "Large-Themes" }).Count
    $small = ($ThemeTypes | Where-Object { $_ -eq "Small-Themes" }).Count
    $visual = ($ThemeTypes | Where-Object { $_ -eq "Visuals-Themes" }).Count

    Write-Color "[L]" "Red"; Write-Color "=Large($large)  " "Gray"
    Write-Color "[S]" "Green"; Write-Color "=Small($small)  " "Gray"
    Write-Color "[V]" "DarkYellow"; Write-Color "=Visual($visual)  " "Gray"
    Write-ColorLine "Total: $($Themes.Count)" "White"
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
    Write-Color "[x]" "Red"; Write-Color " Exit   " "White"
    Write-Color "[b]" "Green"; Write-Color " Backup   " "White"
    Write-Color "[r]" "DarkYellow"; Write-Color " Restore  " "White"
    Write-ColorLine "[p] Preview" "White"
    Write-Color "[f]" "Magenta"; Write-Color " Fonts  " "White"
    Write-Color "[s]" "Blue"; Write-Color " Shell    " "White"
    Write-Color "[d]" "DarkMagenta"; Write-Color " Random   " "White"
    Write-ColorLine "[/] Search" "White"
    Write-Color "[k]" "DarkYellow"; Write-ColorLine " Kitty" "White"
}

# ──────────────────────────────────────────────────────────────
# BACKUP / RESTORE
# ──────────────────────────────────────────────────────────────

function Backup-Config {
    $timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
    $backupDir = Join-Path $ScriptDir "Backup-$timestamp"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    if (Test-Path $ConfigDir) {
        Copy-Item -Path $ConfigDir -Destination $backupDir -Recurse
        Write-ColorLine "OK Backup saved to: $backupDir" "Green"
    } else {
        Write-ColorLine "! No config to backup" "Yellow"
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
        Write-ColorLine "OK Restored from: $($latest.FullName)" "Green"
        Start-Sleep -Seconds 1
        & fastfetch
    } else {
        Write-ColorLine "X No backup found" "Red"
        Start-Sleep -Seconds 1.5
    }
}

# ──────────────────────────────────────────────────────────────
# PROTOCOL PROMPT
# ──────────────────────────────────────────────────────────────

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

# ──────────────────────────────────────────────────────────────
# THEME APPLICATION
# ──────────────────────────────────────────────────────────────

function Apply-Theme {
    param([int]$Index, [bool]$PreviewOnly = $false)

    $themePath = $ThemePaths[$Index]
    $themeName = $Themes[$Index]
    $themeType = $ThemeTypes[$Index]

    if ($PreviewOnly) {
        Write-Color "Previewing " "Cyan"
    } else {
        Write-Color "Applying " "Cyan"
    }
    Write-Color $themeName "Green"
    Write-ColorLine "..." "Cyan"
    Start-Sleep -Milliseconds 300

    if ($PreviewOnly) {
        # Preview: use a temporary directory
        $tmpConfig = Join-Path $env:TEMP "fastfetch-preview-$(Get-Random)"
        New-Item -ItemType Directory -Path $tmpConfig -Force | Out-Null
        Copy-Item -Path (Join-Path $themePath "fastfetch\*") -Destination $tmpConfig -Recurse

        $configFile = Join-Path $tmpConfig "config.jsonc"

        if ($themeType -eq "Visuals-Themes" -and (Test-Path $configFile)) {
            $content = Get-Content $configFile -Raw
            $content = $content -replace '("logo":\s*\{[^}]*"type":\s*")[^"]*(")', "`$1$LogoProtocol`$2"
            $tmpConfigEscaped = $tmpConfig -replace '\\', '/'
            $content = $content -replace '"source":\s*"([^"/][^"]*)"', "`"source`": `"$tmpConfigEscaped/`$1`""
            Set-Content -Path $configFile -Value $content -NoNewline
        }

        Clear-Host
        Write-ColorLine "=== PREVIEW: $themeName ===============================" "Cyan"
        Write-ColorLine "(This is a preview only - your config is NOT changed)" "DarkGray"
        Write-Host ""
        & fastfetch --config $configFile --show-errors
        Remove-Item -Recurse -Force $tmpConfig -ErrorAction SilentlyContinue
    } else {
        # Apply: replace config permanently
        if (Test-Path $ConfigDir) { Remove-Item -Path $ConfigDir -Recurse -Force }
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
        Copy-Item -Path (Join-Path $themePath "fastfetch\*") -Destination $ConfigDir -Recurse

        $configFile = Join-Path $ConfigDir "config.jsonc"

        if ($themeType -eq "Visuals-Themes" -and (Test-Path $configFile)) {
            $content = Get-Content $configFile -Raw
            $content = $content -replace '("logo":\s*\{[^}]*"type":\s*")[^"]*(")', "`$1$LogoProtocol`$2"
            $configDirEscaped = $ConfigDir -replace '\\', '/'
            $content = $content -replace '"source":\s*"([^"/][^"]*)"', "`"source`": `"$configDirEscaped/`$1`""
            Set-Content -Path $configFile -Value $content -NoNewline
        }

        Clear-Host
        Write-Color "Running fastfetch with " "Cyan"
        Write-Color $themeName "Green"
        Write-ColorLine "..." "Cyan"
        Write-Host ""
        & fastfetch --show-errors
    }
}

# ──────────────────────────────────────────────────────────────
# SEARCH THEMES
# ──────────────────────────────────────────────────────────────

function Search-Themes {
    Write-Host ""
    Write-Color "Search theme: " "Yellow"
    $query = Read-Host

    if ([string]::IsNullOrWhiteSpace($query)) {
        Write-ColorLine "Empty search" "Red"
        Start-Sleep -Milliseconds 500
        return
    }

    $found = $false
    Write-Host ""
    Write-ColorLine "Results for '$query':" "Cyan"
    Write-ColorLine "-----------------------------------------------------------" "Gray"

    for ($i = 0; $i -lt $Themes.Count; $i++) {
        if ($Themes[$i] -match [regex]::Escape($query)) {
            $num = $i + 1
            $color = switch ($ThemeTypes[$i]) {
                "Large-Themes"   { "Red" }
                "Small-Themes"   { "Green" }
                "Visuals-Themes" { "DarkYellow" }
                default { "White" }
            }
            Write-Color "  [$num]" "Green"
            Write-Color " $($Themes[$i])" $color
            Write-ColorLine " ($($ThemeTypes[$i]))" "Gray"
            $found = $true
        }
    }

    if (-not $found) {
        Write-ColorLine "  No themes found matching '$query'" "Red"
        Start-Sleep -Seconds 1.5
        return
    }

    Write-ColorLine "-----------------------------------------------------------" "Gray"
    Write-Color "mt3k" "Green"
    Write-Color "@" "White"
    Write-ColorLine "search" "Yellow"
    Write-Color "> " "Red"
    $choice = Read-Host

    if ($choice -match "^\d+$") {
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
}

# ──────────────────────────────────────────────────────────────
# RANDOM THEME
# ──────────────────────────────────────────────────────────────

function Random-Theme {
    $idx = Get-Random -Minimum 0 -Maximum $Themes.Count
    $themeName = $Themes[$idx]
    $themeType = $ThemeTypes[$idx]

    Write-Host ""
    Write-Color "Random pick: " "Magenta"
    Write-Color $themeName "White"
    Write-ColorLine " ($themeType)" "Gray"

    if ($themeType -eq "Visuals-Themes") {
        Prompt-Protocol
    }

    Apply-Theme -Index $idx
    Write-Host ""
    Write-ColorLine "Press enter to continue..." "Green"
    Read-Host | Out-Null
}

# ──────────────────────────────────────────────────────────────
# PREVIEW MODE
# ──────────────────────────────────────────────────────────────

function Preview-Theme {
    Write-Host ""
    Write-Color "Enter theme number to preview: " "Cyan"
    $choice = Read-Host

    if ($choice -match "^\d+$") {
        $idx = [int]$choice - 1
        if ($idx -ge 0 -and $idx -lt $Themes.Count) {
            if ($ThemeTypes[$idx] -eq "Visuals-Themes") {
                Prompt-Protocol
            }
            Apply-Theme -Index $idx -PreviewOnly $true
            Write-Host ""
            Write-ColorLine "Press enter to continue..." "Green"
            Read-Host | Out-Null
        } else {
            Write-ColorLine "Invalid selection" "Red"
            Start-Sleep -Milliseconds 500
        }
    } else {
        Write-ColorLine "Invalid number" "Red"
        Start-Sleep -Milliseconds 500
    }
}

# ──────────────────────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────────────────────

function Main {
    # Check dependencies first
    Check-Fastfetch

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
            "^[fF]$" {
                Install-NerdFonts
            }
            "^[sS]$" {
                Setup-Shell
            }
            "^[dD]$" {
                Random-Theme
            }
            "^[pP]$" {
                Preview-Theme
            }
            "^[kK]$" {
                Install-Kitty
            }
            "^[/\\]$" {
                Search-Themes
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
