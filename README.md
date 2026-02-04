# fastfetch-themes-mt3k

A collection of 52 themes for [fastfetch](https://github.com/fastfetch-cli/fastfetch). Fork of [FastCat](https://github.com/m3tozz/FastCat) with a unified auto-detecting theme selector.

## Features

- **52 themes** organized in 3 categories
- **Auto-detection** - finds all themes automatically
- **Single script** - replaces multiple scripts from original
- **Visual themes** - full image protocol support (kitty, iterm, sixel)
- **Backup/Restore** - never lose your current config

## Theme Categories

| Category | Count | Description |
|----------|-------|-------------|
| Large | 31 | ASCII art logos (big) |
| Small | 16 | ASCII art logos (compact) |
| Visual | 5 | Image-based logos |

## Installation

### Linux / macOS

```bash
# Install fastfetch first
# Linux (Arch): pacman -S fastfetch
# macOS: brew install fastfetch

git clone https://github.com/MondoBoricua/fastfetch-themes-mt3k.git
cd fastfetch-themes-mt3k
chmod +x fastfetch-themes-mt3k
./fastfetch-themes-mt3k
```

### Windows (PowerShell)

```powershell
# Install fastfetch first
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

## Adding New Themes

Create a folder with this structure:

```
YourTheme/
└── fastfetch/
    ├── config.jsonc
    └── logo.txt (or image.png for visual themes)
```

Place it in the appropriate category folder (`Large-Themes/`, `Small-Themes/`, or `Visuals-Themes/`) and the script will detect it automatically.

## Screenshots

<!-- Add your screenshots here -->

## Requirements

- [fastfetch](https://github.com/fastfetch-cli/fastfetch)
- Bash
- Nerd Fonts (for icons)
- For Visual themes: terminal with image support (Kitty, WezTerm, iTerm2, etc.)

### Installing Nerd Fonts

The themes use Nerd Font icons. Install a Nerd Font and set it in your terminal.

**Arch Linux (AUR):**
```bash
git clone https://aur.archlinux.org/ttf-meslo-nerd-font-powerlevel10k.git
cd ttf-meslo-nerd-font-powerlevel10k
makepkg -si
cd ..
```

**Other distros / macOS / Windows:**
Download from [Nerd Fonts](https://www.nerdfonts.com/font-downloads) (recommended: Meslo, JetBrains Mono, or FiraCode)

## Credits

- Original [FastCat](https://github.com/m3tozz/FastCat) by [m3tozz](https://github.com/m3tozz)
- Hacker theme by mt3k

## License

MIT
