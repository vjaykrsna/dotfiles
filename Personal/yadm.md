# 🗂️ Dotfiles Management with `yadm`

This repository is managed using **`yadm` (Yet Another Dotfiles Manager)**.
It uses a **whitelist-based `.gitignore` strategy** and integrates **encryption for secrets**, ensuring reproducibility across machines without leaking private data.

This document is a **master guide** for managing this repo—written so even an AI assistant (or a new human contributor) with zero prior knowledge can confidently handle the setup.

---

## 🚀 Overview of Setup

* **Strategy**:

  * Ignore everything (`*`) by default.
  * Explicitly whitelist files and directories to track.
  * Explicitly blacklist caches, temp files, and noisy configs.
  * Encrypt sensitive files with `yadm-crypt`.

* **What gets tracked**:

  * Core shell dotfiles (`.bashrc`, `.zshrc`, `.profile`, `.gitconfig`, etc.)
  * Personal scripts and projects under `~/Personal/`
  * Select configuration files in `~/.config/` (portable ones like `starship`, `input-remapper`, `micro`, etc.)
  * Autostart entries and wallpapers for reproducible desktop setup
  * User directories (`.config/user-dirs.dirs`) for consistent \$HOME structure

* **What gets excluded**:

  * Caches (`*/cache/`), logs, browser configs, noisy editors like VSCode’s `workspaceStorage/`
  * Browser/session data (`BraveSoftware/`, `Code/`, `chromium/`, etc.)
  * System/runtime files (pulse runtime, ibus socket, ssh agent locks)
  * Shell history files

* **What gets encrypted**:

  * SSH keys (`~/.ssh/`)
  * `.gnupg/` directory (for GPG keys, if you choose to use them)
  * `.env` files
  * Git credentials (`.git-credentials`)
  * GSConnect certs (`certificate.pem`, `private.pem`)

---

## 🔑 Key Files

### `.gitignore`

* Implements the **whitelist approach**.
* Ensures parent directories are un-ignored before child files.
* Sections:

  * Whitelisted dotfiles
  * Whitelisted configs
  * Common ignores (caches, logs, browser profiles, temp)
  * Explicit ignores (history, runtime sockets, junk)

### `.gitattributes`

* Defines which files are handled by `yadm-crypt`.
* Uses:

  ```
  filter=yadm-crypt diff=yadm-crypt merge=yadm-crypt  
  ```

  → Encrypt/decrypt seamlessly when committing/pulling.

### `.config/yadm/encrypt`

* Master list of encrypted paths.
* Drives `yadm encrypt` → creates `~/.local/share/yadm/archive`.
* Examples in current setup: `.ssh/id_*`, `.env`, `gsconnect` keys.

### `.gitmodules`

* Declares Git submodules.
* Current setup:

  * `Personal/myGithub/vscode-settings`

---

## 📦 Daily Workflow

### 1. Check status

```bash
yadm status        # tracked files only  
yadm status -u     # include untracked  
```

### 2. Add changes

```bash
yadm add .         # add all whitelisted changes  
yadm add <file>    # add specific files if needed  
```

### 3. Commit & push

```bash
yadm commit -m "Update <something>"  
yadm push  
```

---

## 🔐 Handling Secrets (Symmetric Encryption)

This setup uses **`openssl` symmetric encryption**, which is simpler and more robust than the GPG default.

*   **How it works**: Your files are encrypted directly with a key derived from your passphrase.
*   **Disaster Recovery**: The **only thing you need to remember is your passphrase**. There is no separate GPG key to back up.

### Encrypting a New File

1.  **Whitelist the file**: Add a `!` rule for the file in your `.gitignore` so `git` can track it.
2.  **Add path to encrypt list**: Add the file's path to `.config/yadm/encrypt`.
3.  **Run `yadm encrypt`**: This will encrypt the new file along with all others.
4.  **Commit changes**: `yadm add .` and `yadm commit`. `yadm` handles the encrypted archive automatically.

### Decrypting on a New Machine

```bash
yadm decrypt
```
This will prompt for your passphrase and restore all your secrets.

---

## 🖥️ Restoring Environment with the Master Script

On a new machine, after cloning and decrypting, the master setup script automates the entire environment restoration.

```bash
# For a fully automated, non-interactive setup:
~/Personal/scripts/setup.sh all

# For an interactive menu:
~/Personal/scripts/setup.sh
```

This script handles:
*   **System Packages**: Installs all `apt`, `flatpak`, `pipx`, `npm`, and `cargo` packages.
*   **GNOME Desktop**: Restores your complete desktop environment—themes, keybindings, fonts, and settings—using `gnome-settings.sh`.
*   **GNOME Extensions**: Reinstalls all your enabled GNOME extensions using `gnome-extensions.sh`.
*   **Shell Environment**: Sets up Zinit and Starship.
*   **System-Level Configs**: The `system-sync.sh` script helps you safely diff and restore configs like `crontab` and `/etc/fstab`.

---

## 🛠️ Customization

### Add a new tracked config

1. Ensure parent directory is whitelisted.
2. Add exact path to `.gitignore` with `!`.
3. Run `yadm add <file>`.

### Add a new encrypted config

Follow the "Encrypt new files" workflow.

### Ignore noisy files

If a config starts creating random junk, add an ignore rule under *Explicitly Ignored*.

---

## ✅ Quick Command Reference

* **Status**: `yadm status -u`
* **Add all**: `yadm add .`
* **Commit**: `yadm commit -m "message"`
* **Push**: `yadm push`
* **Encrypt secrets**: `yadm encrypt && yadm add ~/.local/share/yadm/archive`
* **Decrypt secrets**: `yadm decrypt`

---

## 📌 Notes on Current Setup

* **Whitelist-first strategy** → keeps repo minimal, reproducible, and portable.
* **GNOME dconf tracking enabled** → Restores desktop/session data for a consistent environment.
* **Browser/editor states excluded** → prevents bloat.
* **Personal scripts fully tracked** → ensures your custom tooling is portable.

---

## 🖼️ Handling Large Files with `git lfs`

This repository uses `git lfs` (Large File Storage) to manage large binary files, such as wallpapers. `git lfs` stores the large files on a separate server, and keeps lightweight pointers in the `git` repository.

### Current `git lfs` Configuration

*   **Tracked files**:
    * `*.png` and `*.jpg` files in the `Personal/Wallpaper/` directory.
    * Font files (`.ttf`, `.otf`, `.woff`, `.woff2`) in the `.local/share/fonts/` directory.

### Workflow for Large Files

1.  **Add the file**: Place the large file in the appropriate directory (e.g., `Personal/Wallpaper/` or `.local/share/fonts/`).
2.  **Track the file type**: If it's a new file type, run `yadm lfs track "*.new_extension"`.
3.  **Add the file to git**: Run `yadm add <path_to_file>`.
4.  **Commit and push**: Commit and push your changes as usual.

---
