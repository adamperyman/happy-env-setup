#!/bin/bash

# A hacky little setup script to automate the creation of VMs.
# Author: Adam Peryman <adam.peryman@gmail.com>
# Tested on Ubuntu 16.04 LTS

if [ -z ${USER_NAME+x} ]; then
  echo "ENV var USER_NAME is undefined."

  echo -n "Please enter new username: "
  read USER_NAME
fi

if [ -z ${USER_PASS+x} ]; then
  echo "ENV var USER_PASS is undefined."

  password_valid=0
  while [ $password_valid == 0 ]; do
    read -s -p "Please enter new password: " user_pass1
    echo

    read -s -p "Please enter new password (again): " user_pass2
    echo

    if [ "$user_pass1" == "$user_pass2" ]; then
      password_valid=1
      USER_PASS=$user_pass1
    else
      echo "Passwords don't match! Try again.."
    fi
  done
fi

if [ -z ${USER_EMAIL+x} ]; then
  echo "ENV var USER_EMAIL is undefined."

  echo -n "Please enter the new user's email: "
  read USER_EMAIL
fi

if [ -z ${SSH_ENCRYPTION_ALGORITHM+x} ]; then
  echo "ENV var SSH_ENCRYPTION_ALGORITHM is undefined."

  encryption_algorithm_valid=0
  while [ $encryption_algorithm_valid == 0 ]; do
    read -p "Please enter SSH encryption algorithm (ed25519 or rsa): " SSH_ENCRYPTION_ALGORITHM
    echo

    if [ "$SSH_ENCRYPTION_ALGORITHM" == "ed25519" ] || [ "$SSH_ENCRYPTION_ALGORITHM" == "rsa" ]; then
      encryption_algorithm_valid=1
    else
      echo "Invalid encryption algorithm specified, try again.."
    fi
  done
fi

apt_switches="-qq -o=Dpkg::Use-Pty=0" # Silence all output except errors.
apt_update_cmd="apt-get $apt_switches update"
apt_install_cmd="apt-get $apt_switches install"

# Setup SSH for root if necessary, use Ed25519 (new) or RSA depending on your needs.
if [ ! -d "$HOME/.ssh/" ]; then
  if [ "$SSH_ENCRYPTION_ALGORITHM" == "ed25519" ]; then
    echo "Creating SSH keys for ROOT user using $SSH_ENCRYPTION_ALGORITHM algorithm.."
    ssh-keygen -t ed25519 -a 100 -N "" -C $USER_EMAIL -f $HOME/.ssh/id_ed25519
  elif [ "$SSH_ENCRYPTION_ALGORITHM" == "rsa" ]; then
    echo "Creating SSH keys for ROOT user using RSA algorithm.."
    ssh-keygen -t rsa -b 4096 -o -a 100 -N "" -C $USER_EMAIL -f $HOME/.ssh/id_rsa
  else
    echo "Unknown SSH_ENCRYPTION_ALGORITHM, defaulting to RSA."
    echo "Creating SSH keys for ROOT user using RSA algorithm.."
    ssh-keygen -t rsa -b 4096 -o -a 100 -N "" -C $USER_EMAIL -f $HOME/.ssh/id_rsa
  fi

  echo "Finished creating SSH keys."
else
  echo "$HOME/.ssh directory already exists, skipping SSH key generation for ROOT user.."
fi

# Install deps.
$apt_update_cmd && $apt_install_cmd whois git apt-utils

# Get password hash.
echo "Creating hashed password.."
HASHED_PASSWORD=$(mkpasswd -m sha-512 $USER_PASS)

if [ -z ${HASHED_PASSWORD+x} ]; then
  echo "Failed to create hashed password.."
  exit 1
fi

echo "Hashed password created successfully."

# Create user.
echo "Creating user: $USER_NAME.."
if useradd -m -p $HASHED_PASSWORD -s /bin/bash $USER_NAME; then
  echo "User: $USER_NAME created successfully."
else
  echo "Failed to create user: $USER_NAME."
  exit 1
fi

echo "Assigning group permissions.."
if usermod -aG sudo $USER_NAME; then
  echo "Successfully assigned $USER_NAME to sudo group."
else
  echo "Failed to assign $USER_NAME to sudo group."
  exit 1
fi

su $USER_NAME -c "bash user-setup.sh $USER_NAME $USER_PASS $USER_EMAIL $SSH_ENCRYPTION_ALGORITHM"
