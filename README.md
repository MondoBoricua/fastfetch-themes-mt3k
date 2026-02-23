# fastfetch-themes-mt3k

A collection of 52 themes for [fastfetch](https://github.com/fastfetch-cli/fastfetch). Fork of [FastCat](https://github.com/m3tozz/FastCat) with a unified auto-detecting theme selector.

## Features

- **52 themes** organized in 3 categories
- **Auto-detection** - finds all themes automatically
- **Single script** - replaces multiple scripts from original
- **Visual themes** - full image protocol support (kitty, iterm, sixel)
- **Backup/Restore** - never lose your current config
- **Preview mode** - test themes without changing your config
- **Search** - find themes by name
- **Random theme** - feeling lucky? pick a random theme
- **Nerd Fonts installer** - download and install popular Nerd Fonts
- **Kitty installer** - install Kitty terminal for image support
- **Shell auto-start** - configure fastfetch to run on terminal open
- **Dependency checks** - auto-detect and install fastfetch if missing

## Theme Categories

| Category | Count | Description |
|----------|-------|-------------|
| Large | 31 | ASCII art logos (big) |
| Small | 16 | ASCII art logos (compact) |
| Visual | 5 | Image-based logos |

## Installation

### Linux / macOS

```bash
# Install fastfetch first (or let the script do it for you!)
# Linux (Arch): pacman -S fastfetch
# macOS: brew install fastfetch

git clone https://github.com/MondoBoricua/fastfetch-themes-mt3k.git
cd fastfetch-themes-mt3k
chmod +x fastfetch-themes-mt3k
./fastfetch-themes-mt3k
```

### Windows (PowerShell)

```powershell
# Install fastfetch first (or let the script do it for you!)
winget install Fastfetch

git clone https://github.com/MondoBoricua/fastfetch-themes-mt3k.git
cd fastfetch-themes-mt3k
.\fastfetch-themes-mt3k.ps1
```

## Usage

### Linux / macOS
```bash
./fastfetch-themes-mt3k
```

### Windows
```powershell
.\fastfetch-themes-mt3k.ps1
```

### Controls

| Key | Action |
|-----|--------|
| `1-52` | Select theme by number |
| `b` | Backup current config |
| `r` | Restore last backup |
| `p` | Preview a theme without applying |
| `d` | Apply a random theme |
| `/` | Search themes by name |
| `f` | Install Nerd Fonts |
| `k` | Install Kitty terminal |
| `s` | Setup shell auto-start |
| `x` | Exit |

### Image Protocols (Visual Themes)

When selecting a Visual theme, you'll be prompted to choose an image protocol:

| Protocol | Supported Terminals |
|----------|---------------------|
| `auto` | Kitty, Ghostty (auto-detect) |
| `kitty` | Kitty |
| `kitty-direct` | WezTerm, Warp, Kitty, Ghostty (fastest) |
| `iterm` | iTerm2, WezTerm, Konsole |
| `sixel` | foot, Contour |

### Nerd Fonts Installer `[f]`

Download and install popular Nerd Fonts directly from the script:

- JetBrainsMono (recommended)
- Meslo
- FiraCode
- Hack
- CascadiaCode
- UbuntuMono
- SourceCodePro

### Kitty Terminal Installer `[k]`

Install the Kitty GPU-accelerated terminal with image support:

**Linux/macOS:**
- Package manager (pacman, apt, dnf, zypper, brew, nix)
- Official installer script from kovidgoyal.net (recommended)
- Flatpak

**Windows:**
- winget (recommended)
- scoop
- Chocolatey
- GitHub release download

### Shell Auto-Start `[s]`

Configure fastfetch to run automatically when you open a terminal:

- **Bash** (~/.bashrc)
- **Zsh** (~/.zshrc)
- **Fish** (~/.config/fish/config.fish)
- **PowerShell** (Windows profile)
- **Git Bash** (Windows ~/.bashrc)

Run the option again to remove auto-start.

## Adding New Themes

The script **auto-detects** any new theme you add. Just create a folder with this structure:

```
YourTheme/
└── fastfetch/
    ├── config.jsonc
    └── logo.txt (or image.png for visual themes)
```

Drop it in the appropriate category folder:
- `Large-Themes/` - ASCII art (big)
- `Small-Themes/` - ASCII art (compact)
- `Visuals-Themes/` - Image-based themes

Run the script and your theme will appear in the menu automatically. No code changes needed.

## Screenshots

<!-- Add your screenshots here -->

## Requirements

- [fastfetch](https://github.com/fastfetch-cli/fastfetch) (auto-installed if missing)
- Bash (Linux/macOS) or PowerShell (Windows)
- Nerd Fonts (installable via `[f]` option)
- For Visual themes: terminal with image support like Kitty (installable via `[k]` option)

## Credits

- Original [FastCat](https://github.com/m3tozz/FastCat) by [m3tozz](https://github.com/m3tozz)
- Hacker theme by mt3k

## License

MIT
