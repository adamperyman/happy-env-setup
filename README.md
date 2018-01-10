# happy-env-setup

A collection of scripts to make setting up dev environments a lot easier.

![](https://media.giphy.com/media/Ls6ahtmYHU760/giphy.gif)

# What?

#### Phase 1
* Prompts for new user name, pass, email, and SSH key encryption algorithm (Ed25519 or RSA).
* Attempts to create SSH keys for root user **if `/root/.ssh` directory doesn't exist**.
* Runs `apt-get update` and installs several packages required for the script.
* Creates a new user from the data provided initially, assigns user to sudo group.

#### Phase 2
* Installs packages required for docker.
* Installs docker-ce.
  * Adds docker GPG key.
  * Adds docker repository.
* Installs docker-compose.
* Assigns new user to docker group (no more `sudo docker ..`).
* Generates SSH keys for new user.
  * Creates `authorized_keys` file.
* Prompts user for any public keys to assign to `authorized_keys` file (able to SSH into machine as new user immediately).
* Installs Vim, Amix's [.vimrc](https://github.com/amix/vimrc), and applies my custom Vim [settings](https://github.com/x0bile/vim-settings).
* Outputs new user's public SSH key for easy copying to whatever services may require it.

# Usage

1. Login/SSH into *fresh* new environment.
2. Clone this repository.
     * `git clone https://github.com/x0bile/happy-env-setup.git`
3. Run `bash setup.sh` and follow the instructions.
