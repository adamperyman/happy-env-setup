#!/bin/bash

USER_NAME=$1
USER_PASS=$2
USER_EMAIL=$3
SSH_ENCRYPTION_ALGORITHM=$4

new_user_home_dir=$(eval echo "~$USER_NAME")

apt_switches="-qq -o=Dpkg::Use-Pty=0" # Silence all output except errors.
apt_update_cmd="apt-get $apt_switches update"
apt_install_cmd="apt-get $apt_switches install"

if [ -z ${new_user_home_dir:x} ]; then
  echo "Failed to find home directory for user: $USER_NAME."
  exit 1
fi

# Clean up.
sudo -S apt-get remove docker docker-engine docker.io

# Here we go.
sudo $apt_update_cmd && \
  sudo $apt_install_cmd \
    linux-image-extra-$(uname -r) \
    linux-image-extra-virtual \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Docker GPG key
echo "Adding Docker GPG key.."
if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -; then
  echo "Successfully added Docker GPG key."
else
  echo "Failed to add Docker GPG key."
  exit 1
fi

sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

sudo $apt_update_cmd && sudo $apt_install_cmd docker-ce

sudo apt-key fingerprint 0EBFCD88
if [ $? -eq 0 ]; then
  echo "Docker installed successfully!"
else
  echo "Failed to get Docker GPG key.."
  exit 1
fi

echo "Installing docker-compose.."

sudo curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

if docker-compose --version; then
  echo "docker-compose installed successfully!"
else
  echo "docker-compose install failed."
  exit 1
fi

echo "Finished installing docker."

echo "Assigning $USER_NAME to docker group.."
sudo groupadd docker
if sudo usermod -aG docker $USER_NAME; then
  echo "Successfully added $USER_NAME to docker group."
else
  echo "Failed to add $USER_NAME to docker group."
  # Don't need to exit here, investigate manually.
fi

# Setup SSH, use Ed25519 (new) or RSA depending on your needs.
if [ "$SSH_ENCRYPTION_ALGORITHM" == "ed25519" ]; then
  echo "Creating SSH keys using $SSH_ENCRYPTION_ALGORITHM algorithm.."
  ssh-keygen -t ed25519 -a 100 -N "" -C $USER_EMAIL -f $new_user_home_dir/.ssh/id_ed25519
elif [ "$SSH_ENCRYPTION_ALGORITHM" == "rsa" ]; then
  echo "Creating SSH keys using RSA algorithm.."
  ssh-keygen -t rsa -b 4096 -o -a 100 -N "" -C $USER_EMAIL -f $new_user_home_dir/.ssh/id_rsa
else
  echo "Unknown SSH_ENCRYPTION_ALGORITHM, defaulting to RSA."
  echo "Creating SSH keys using RSA algorithm.."
  ssh-keygen -t rsa -b 4096 -o -a 100 -N "" -C $USER_EMAIL -f $new_user_home_dir/.ssh/id_rsa
fi

echo "Finished creating SSH keys."

# Generate authorized_keys.
if [ ! -f "$new_user_home_dir/.ssh/authorized_keys" ]; then
  echo "authorized_keys file not found for User: $USER_NAME, creating now.."

  touch $new_user_home_dir/.ssh/authorized_keys
  sudo chown $USER_NAME $new_user_home_dir/.ssh/authorized_keys

  echo "Finished creating authorized_keys file."
fi

enter_pub_key=y
while [ "$enter_pub_key" != "n" ]; do
  read -p "Would you like to add a public SSH key to User: $USER_NAME's authorized_keys file? (y/n): " enter_pub_key
  echo

  if [ "$enter_pub_key" == "y" ]; then
    read -p "Please enter public key then press enter: " pub_key
    echo

    echo $pub_key >> $new_user_home_dir/.ssh/authorized_keys

    echo "Successfully added public key to $USER_NAME's authorized_keys."
  else
    enter_pub_key=n
  fi
done

# Setup Vim.
# Installing vim-gnome is the lazy man's way of ensuring Vim was compiled with the +clipboard flag.
sudo $apt_update_cmd && sudo $apt_install_cmd vim-gnome

# Amix's .vimrc.
if sudo git clone --depth=1 https://github.com/amix/vimrc.git $new_user_home_dir/.vim_runtime; then
  bash $new_user_home_dir/.vim_runtime/install_awesome_vimrc.sh

  # AP's custom settings.
  mkdir -p $new_user_home_dir/dev
  sudo git clone https://github.com/x0bile/vim-settings.git $new_user_home_dir/dev/vim-settings

  # Sub-shell to create new working dir for setup.sh.
  (cd $new_user_home_dir/dev/vim-settings ; sudo -S sh $new_user_home_dir/dev/vim-settings/setup.sh)
else
  echo "Failed to get Amix's .vimrc, didn't setup AP's custom settings."
fi

# Output.
echo "You should add the following PUBLIC key to any services that require it, e.g. Github.."
cat $new_user_home_dir/.ssh/id_$SSH_ENCRYPTION_ALGORITHM.pub

echo "We're done here, please logout and back in to refresh user groups for user: $USER_NAME."
echo "Have a wonderful day! :)"
