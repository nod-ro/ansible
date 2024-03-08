#!/bin/bash

confirm_action() {
    while true; do
        read -p "Sigur doresti sa continui? Acest script va actualiza o masina deja existenta Ansible cu versiunine din environment.yml (da/nu) " yn
        case $yn in
            [Dd]* ) break;; # If yes, exit the loop
            [Nn]* ) echo "Operation aborted."; exit;; # If no, abort the operation
            * ) echo "Raspunde cu da sau nu.";; # If any other input, ask again
        esac
    done
}

confirm_action

# Assuming environment.yml is in the current directory and yq is installed
WEBSITES_LENGTH=$(yq eval '.websites | length' websites.yml)
yq eval ".websites[$i] | {public_plugins, plugins, themes}" websites.yml > temp_vars.yml
for ((i = 0 ; i < $WEBSITES_LENGTH ; i++ )); do
    DEVELOPMENT_DOMAIN=$(yq eval ".websites[$i].name" websites.yml)
    REMOTE_HOST=$(yq eval ".websites[$i].vm_ip" websites.yml)
    REMOTE_USER=$(yq eval ".websites[$i].vm_user" websites.yml)
    REMOTE_PASSWORD=$(yq eval ".websites[$i].vm_password" websites.yml)
    LOCAL_SSH_PRIVATE_KEY_PATH=$(yq eval '.ssh_key_path' websites.yml)
    REMOTE_MYSQL_PRIVATE_KEY_PATH=$(yq eval '.remote_mysql_cert_path' websites.yml)

    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    GIT_REPO_URL="https://github.com/nod-ro/ansible.git"

    # Upload SSH private key for Git operations
    sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no "$LOCAL_SSH_PRIVATE_KEY_PATH" "$REMOTE_USER@$REMOTE_HOST:/tmp/private_key"
# Install Ansible, Git, clone the repository, and clean up
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" GIT_REPO_URL="$GIT_REPO_URL" bash -s << 'EOF'
chmod 600 /tmp/private_key
eval $(ssh-agent -s)
ssh-add /tmp/private_key
ssh -Tvvv git@github.com
sudo rm -rf /var/ansible
sudo git clone $GIT_REPO_URL /var/ansible
sudo chown -R $USER:$USER /var/ansible

EOF

# Connect to the VM and run multiple commands
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" bash -s << 'EOF'

cd /var/ansible
ls -la
sudo su -
export LC_ALL=C
export LANG=C
export LANGUAGE=C
#apt-get update
#apt-get install -y locales
locale-gen en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
ls -la /var/ansible



ansible-playbook /var/ansible/upgrade.yml -e "development_domain=${DEVELOPMENT_DOMAIN}" -e @temp_vars.yml

EOF
done