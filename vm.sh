#!/bin/bash

# Parse variables from the local environment.yml file
REMOTE_HOST=$(yq eval '.vm_ip' environment.yml)
REMOTE_USER=$(yq eval '.vm_user' environment.yml)
REMOTE_PASSWORD=$(yq eval '.vm_password' environment.yml)

LOCAL_SSH_PRIVATE_KEY_PATH="/home/spanzuratorul/.ssh/ansible_remote_key"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GIT_REPO_URL="https://github.com/nod-ro/ansible.git"

# Upload SSH private key for Git operations
sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no "$LOCAL_SSH_PRIVATE_KEY_PATH" "$REMOTE_USER@$REMOTE_HOST:/tmp/private_key"

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

#ssh -Tvvv git@github.com

sudo rm -rf /var/ansible
sudo git clone $GIT_REPO_URL /var/ansible

# Change ownership of /var/ansible to the remote user
sudo chown -R $USER:$USER /var/ansible

EOF

# Upload environment.yml from the local machine to the remote VM
sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no "$SCRIPT_DIR/environment.yml" "$REMOTE_USER@$REMOTE_HOST:/var/ansible/"

# Connect to the VM and run multiple commands
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" bash -s << 'EOF'

#ansible-playbook setup.yml
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
ansible-playbook /var/ansible/setup.yml
EOF