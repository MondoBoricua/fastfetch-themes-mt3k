# fastfetch-themes-mt3k

A collection of 52 themes for [fastfetch](https://github.com/fastfetch-cli/fastfetch). Fork of [FastCat](https://github.com/m3tozz/FastCat) with a unified auto-detecting theme selector.

## Features

- **52+ themes** organized in 3 categories
- **Auto-detection** - finds all themes automatically
- **Single script** - replaces multiple scripts from original
- **Visual themes** - full image protocol support (kitty, iterm, sixel)
- **Backup/Restore** - smart backup management with auto-prune
- **Preview mode** - test themes without changing your config
- **Search** - find themes by name
- **Random theme** - random by category (all/large/small/visual)
- **Favorites** - mark and quick-access your preferred themes
- **History** - track your last 10 applied themes
- **Category filter** - show only Large, Small, or Visual themes
- **Slideshow** - auto-preview all themes with configurable delay
- **Theme info** - view modules, images, size, and validation status
- **Git updates** - pull new themes from GitHub with one keypress
- **CLI arguments** - use without interactive menu (--apply, --list, etc.)
- **Nerd Fonts installer** - download and install popular Nerd Fonts
- **Kitty installer** - install Kitty terminal for image support
- **Shell auto-start** - configure fastfetch to run on terminal open
- **Desktop notifications** - get notified when a theme is applied
- **JSON validation** - validate configs before applying
- **Dependency checks** - auto-detect and install fastfetch if missing

## Theme Categories

| Category | Count | Description               |
| -------- | ----- | ------------------------- |
| Large    | 31    | ASCII art logos (big)     |
| Small    | 16    | ASCII art logos (compact) |
| Visual   | 7     | Image-based logos         |

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

### Interactive Mode

```bash
# Linux / macOS
./fastfetch-themes-mt3k

# Windows
.\fastfetch-themes-mt3k.ps1
```

### CLI Mode (non-interactive)

```bash
./fastfetch-themes-mt3k --apply "Hacker"        # Apply theme by name
./fastfetch-themes-mt3k --preview "Toga-Himiko"  # Preview without applying
./fastfetch-themes-mt3k --random                 # Apply random theme
./fastfetch-themes-mt3k --random visual          # Random from category
./fastfetch-themes-mt3k --list                   # List all themes
./fastfetch-themes-mt3k --list large             # List by category
./fastfetch-themes-mt3k --search "hack"          # Search themes
./fastfetch-themes-mt3k --update                 # Update from git
./fastfetch-themes-mt3k --favorites              # Show favorites
./fastfetch-themes-mt3k --history                # Show history
./fastfetch-themes-mt3k --version                # Show version
./fastfetch-themes-mt3k --help                   # Show help
```

### Interactive Controls

| Key   | Action                                             |
| ----- | -------------------------------------------------- |
| `1-N` | Select theme by number                             |
| `b`   | Backup current config (auto-prunes to 5 max)       |
| `r`   | Restore from backup (choose from list)             |
| `p`   | Preview a theme without applying                   |
| `d`   | Random theme (by category: all/large/small/visual) |
| `/`   | Search themes by name                              |
| `f`   | Install Nerd Fonts                                 |
| `k`   | Install Kitty terminal                             |
| `s`   | Setup shell auto-start                             |
| `u`   | Update themes via git pull                         |
| `v`   | Favorites menu                                     |
| `+`   | Toggle favorite for a theme                        |
| `h`   | Show theme history (last 10)                       |
| `c`   | Filter by category (Large/Small/Visual/All)        |
| `w`   | Slideshow mode (auto-preview all themes)           |
| `i`   | Theme info (modules, images, validation)           |
| `x`   | Exit                                               |

### Image Protocols (Visual Themes)

When selecting a Visual theme, you'll be prompted to choose an image protocol:

| Protocol       | Supported Terminals                     |
| -------------- | --------------------------------------- |
| `auto`         | Kitty, Ghostty (auto-detect)            |
| `kitty`        | Kitty                                   |
| `kitty-direct` | WezTerm, Warp, Kitty, Ghostty (fastest) |
| `iterm`        | iTerm2, WezTerm, Konsole                |
| `sixel`        | foot, Contour                           |

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
