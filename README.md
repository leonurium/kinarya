# kinarya

Lightweight, self-contained **bash** tool that turns a factory-fresh Mac into your working
machine by replaying your manual new-device workflow — with a menu, a resumable state file, and
**no third-party dependencies** (built-in macOS tools only).

## Requirements

- macOS (Apple Silicon or Intel)
- Login shell `zsh` (default)
- The USB drive mounted (auto-detected; it looks for a folder named `MacOS` and/or `Workspaces`)

## Layout

```
kinarya
├── kinarya                     entry script (menu + flags)
├── lib/                        common, state, config, fs, install helpers
├── modules/                    01-brew 02-core 03-software 03-xcode 03-workspaces 04-gh 05-prefs 06-finalize
└── config/kinarya.conf.example path/mapping overrides
```

## Usage

```sh
./kinarya                 # interactive menu
./kinarya --all           # run every step in order
./kinarya --step xcode    # run one step (name or number)
./kinarya --list          # show steps and status
./kinarya --dry-run --all # preview, change nothing
./kinarya --force --step prefs
./kinarya --clear         # reset progress
```

State lives in `~/.kinarya/state`; completed steps are skipped on re-run unless `--force`.

## Steps

| # | Step | What it does |
|---|------|--------------|
| 1 | `brew` | Installs Homebrew and writes `brew shellenv` into `~/.zprofile` |
| 2 | `core` | `brew install mole node cocoapods` |
| 3 | `software` | Scans the USB `MacOS` folder, multi-select, copies to `~/Downloads/Software`, installs each pick |
| 4 | `xcode` | Picks Xcode `.xip` version(s), expands, installs as `/Applications/Xcode_<ver>.app`, sets up CLT + `xcode-select` + license, adds simulator runtimes |
| 5 | `workspaces` | Copies `Archive` → `~/Downloads/Archive`, `Document` → `~/Downloads/Document`, `project` → `~/project` |
| 6 | `flutter` | Picks the Flutter zip matching this Mac's chip (`arm64`/`x64`), unzips it into `~/project`, and adds `~/project/flutter/bin` to `~/.zprofile` |
| 7 | `zsh` | Installs Oh My Zsh, clones the Powerlevel10k theme, sets `ZSH_THEME="powerlevel10k/powerlevel10k"`, and applies a preset as `~/.p10k.zsh` (default **rainbow**; override with `KINARYA_P10K`) |
| 8 | `gh` | Installs GitHub CLI, signs in via browser, and sets global `user.name` / `user.email` |
| 9 | `prefs` | Dock (size/magnification/auto-hide/icons), trackpad tap-to-click, clock seconds, battery % |
| 10 | `finalize` | Prints the manual checklist (Apple ID, Find My, Location, More Space, sidebar, announce time, Nerd Font) |

### Installer handling

- `.pkg` → `installer -pkg … -target /`
- `.dmg` → mount; if it holds an `.app` it is copied to `/Applications`, if a `.pkg` it is installed; then detached
- `.xip` → `xip --expand` (Xcode only; handled by the `xcode` step)
- `.zip` → extracted; any `.app` inside is copied to `/Applications`
- `.app` (folder) → copied to `/Applications`

### Dock numbers

`size ≈ 32px` and `magnification ≈ 72px` — i.e. 15% and 50% of the Dock slider range (16–128).

## Manual steps (not automatable without extra tools)

1. Sign in to Apple ID; enable Find My and Location Services.
2. Displays → **More Space**.
3. Drag `~/project` into the Finder sidebar, below Downloads.
4. Clock → Announce the time.
5. Log out/in if trackpad tap-to-click did not apply.

## Shipping to a new Mac

kinarya is self-contained — copy this whole folder onto the USB drive (e.g. the `MacOS` folder or
the drive root) and run `./kinarya` there. Nothing else needs to be installed first.

## Troubleshooting: the first run looks "stuck" on Homebrew

When Homebrew is missing, its installer also installs the **Xcode Command Line Tools** via Apple
Software Update — a large (~1–3 GB) download with **no progress bar** that can take a long time.
The terminal is not frozen; it is downloading. Check from a second Terminal window:

```sh
ps aux | grep -iE 'softwareupdate|installer' | grep -v grep   # is it running
sudo du -sh /Library/Updates 2>/dev/null                       # growing = still downloading
sudo tail -f /var/log/install.log                              # live install log
pkgutil --pkg-info=com.apple.pkg.CLTools_Executables && xcode-select -p  # done when it prints a version
```

If it truly hangs (no process, no log growth), run `xcode-select --install` first, let it finish,
then re-run kinarya — the CLT will already be present.

