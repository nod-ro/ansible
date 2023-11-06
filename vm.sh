#!/bin/bash

# Parse variables from the local environment.yml file
REMOTE_HOST=$(yq read environment.yml 'vm_ip')
REMOTE_USER=$(yq read environment.yml 'vm_user')
REMOTE_PASSWORD=$(yq read environment.yml 'vm_password')

LOCAL_SSH_PRIVATE_KEY_PATH=$(yq read environment.yml 'ssh_key_path')
LOCAL_MYSQL_PRIVATE_KEY_PATH=$(yq read environment.yml 'local_mysql_cert_path')
REMOTE_MYSQL_PRIVATE_KEY_PATH=$(yq read environment.yml 'remote_mysql_cert_path')

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GIT_REPO_URL="https://github.com/nod-ro/ansible.git"

# Upload SSH private key for Git operations
sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no "$LOCAL_SSH_PRIVATE_KEY_PATH" "$REMOTE_USER@$REMOTE_HOST:/tmp/private_key"
sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no "$LOCAL_MYSQL_PRIVATE_KEY_PATH" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_MYSQL_PRIVATE_KEY_PATH"

# Install Ansible, Git, clone the repository, and clean up
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" GIT_REPO_URL="$GIT_REPO_URL" bash -s << 'EOF'

#sudo apt-get update
#sudo apt-get install -y software-properties-common
#sudo add-apt-repository --yes --update ppa:ansible/ansible
#sudo apt-get install -y ansible
#sudo apt-get install -y git

# Configure SSH key for Git operations
chmod 600 /tmp/private_key
eval $(ssh-agent -s)
ssh-add /tmp/private_key

ssh -Tvvv git@github.com

sudo rm -rf /var/ansible
sudo git clone $GIT_REPO_URL /var/ansible

# Change ownership of /var/ansible to the remote user
sudo chown -R $USER:$USER /var/ansible

EOF

# Upload environment.yml from the local machine to the remote VM
sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no "$SCRIPT_DIR/environment.yml" "$REMOTE_USER@$REMOTE_HOST:/var/ansible/"

# Connect to the VM and run multiple commands
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" bash -s << 'EOF'

cd /var/ansible
ls -la
sudo su -
export LC_ALL=C
export LANG=C
export LANGUAGE=C
apt-get update
apt-get install -y locales
locale-gen en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
ls -la /var/ansible



#ansible-playbook /var/ansible/setup.yml --tags menus
#ansible-playbook /var/ansible/setup.yml --tags pages
#ansible-playbook /var/ansible/setup.yml --tags shipping
ansible-playbook /var/ansible/setup.yml

EOF
