# My Dotfiles

This repository contains my personal dotfiles, managed with [yadm](https://yadm.io/).

## Restoring Setup on a New Machine

1.  **Install Prerequisites:**
    Run the following command to install `yadm` and other essential tools:
    ```bash
    sudo apt-get update && sudo apt-get install -y git curl git-lfs && sudo curl -fsLo /usr/local/bin/yadm https://github.com/yadm-dev/yadm/raw/master/yadm && sudo chmod a+x /usr/local/bin/yadm
    ```

2.  **Clone Repository:**
    Clone this repository using `yadm`:
    ```bash
    yadm clone https://github.com/vjaykrsna/dotfiles.git
    ```

3.  **Decrypt Secrets:**
    Restore encrypted files (like SSH keys):
    ```bash
    yadm decrypt
    ```

4.  **Run Setup Script:**
    Run the master setup script to automatically restore your entire environment.
    
    For a fully automated, non-interactive setup, run:
    ```bash
    ~/Personal/scripts/setup.sh all
    ```
    
    For an interactive menu with all options, run:
    ```bash
    ~/Personal/scripts/setup.sh
