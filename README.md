# Portable dotfiles

Portable shell, Vim, Neovim, and tmux configuration for macOS, Arch Linux,
Ubuntu, WSL, and restricted machines.

The installer never starts tmux automatically. It copies regular files and
backs up existing files before replacing them.

## Install

```sh
git clone git@github.com:iragonforce/dotfiles.git
cd dotfiles
./install.sh
```

Modes:

- `safe`: copy configuration only. No network, sudo, package manager, or plugin installation.
- `essential`: install core shell/editor packages when available, but no third-party frameworks or plugins.
- `mirror`: install the curated toolchain, optionally install the full macOS application set, and install declared frameworks and plugins.

Non-interactive examples:

```sh
./install.sh --mode safe
./install.sh --mode essential
./install.sh --mode mirror
./install.sh --dry-run
```

Existing files are backed up under `~/.dotfiles-backup/`.

## Branches

- `main`: portable installer and shared configuration.
- `platform/macos`: macOS and Homebrew overlay.
- `platform/linux`: Arch, Ubuntu, and WSL overlay.
- `platform/restricted`: configuration-only snapshot.

## Safety

Run `scripts/audit-public.sh` before committing. It rejects private keys,
credentials, tokens, shell histories, editor state, absolute personal paths,
generated plugin trees, and other non-portable files.

Oh My Zsh and editor plugins are represented by manifests and installed from
their official repositories only in `mirror` mode. They are not vendored into
this repository.
