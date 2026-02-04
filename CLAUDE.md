# FastCat

Coleccion de temas para fastfetch. Fork de https://github.com/m3tozz/FastCat

## Reglas para Claude

- NUNCA ponerse como co-autor en commits (no usar Co-Authored-By)

## Estructura

```
FastCat/
├── fastfetch-themes-mt3k      # Script principal Linux/macOS (bash)
├── fastfetch-themes-mt3k.ps1  # Script principal Windows (PowerShell)
├── Large-Themes/              # 31 temas con ASCII art grande
├── Small-Themes/              # 16 temas con ASCII art pequeno
├── Visuals-Themes/            # 4 temas con imagenes (kitty protocol)
│   └── Hacker/                # Mi tema custom
└── Backup-*/                  # Backups automaticos
```

## Plataformas soportadas

| OS | Script | Instalacion fastfetch |
|----|--------|----------------------|
| Linux | `./fastfetch-themes-mt3k` | `pacman -S fastfetch` |
| macOS | `./fastfetch-themes-mt3k` | `brew install fastfetch` |
| Windows | `.\fastfetch-themes-mt3k.ps1` | `winget install Fastfetch` |

## Script: fastfetch-themes-mt3k

Script custom que reemplaza los scripts originales. Detecta automaticamente todos los temas.

### Caracteristicas

- Detecta temas automaticamente de las 3 carpetas
- Colores por categoria: ROJO=Large, LIME=Small, NARANJA=Visual
- `[b]` Backup antes de cambiar tema
- `[r]` Restaurar ultimo backup
- `[x]` Salir
- Visual themes: pregunta protocolo de imagen antes de aplicar

### Protocolos de imagen (Visual themes)

| Protocolo | Terminales soportadas |
|-----------|----------------------|
| auto | Kitty, Ghostty (auto-detect) |
| kitty | Kitty |
| kitty-direct | WezTerm, Warp, Kitty, Ghostty (PNG only) - mas rapido |
| iterm | iTerm2, WezTerm, Konsole |
| sixel | foot, Contour |

### Uso

```bash
./fastfetch-themes-mt3k
```

### Implementacion tecnica

El script usa sed contextual para modificar solo el bloque `logo` sin afectar los modulos:
```bash
sed -i '/"logo": {/,/}/ s/"type": ".*"/"type": "PROTOCOL"/' config.jsonc
```

## Tema personalizado: Hacker

Mi tema esta en `Visuals-Themes/Hacker/`:
- Imagen: `hacker000.png` (optimizada a 800x800)
- Estilo: Basado en Anime-Girl con iconos nerd fonts
- Protocolo: kitty-direct

Para aplicar manualmente:
```bash
cp -r Visuals-Themes/Hacker/fastfetch ~/.config/
```

## Agregar nuevos temas

Solo crear carpeta con estructura:
```
NombreTema/
└── fastfetch/
    ├── config.jsonc
    └── ascii.txt (o imagen.png para visual)
```

El script lo detecta automaticamente.

## Community Themes

PR enviado a https://github.com/m3tozz/fastcat-community-themes con tema Hacker.

## Notas

- Visual themes requieren terminal con kitty graphics (kitty, ghostty, wezterm)
- Backups en carpetas `Backup-YYYY-MM-DD-HH:MM:SS`
- Config de fastfetch: `~/.config/fastfetch/config.jsonc`
