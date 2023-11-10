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

# Connect to the VM and run multiple commands
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" bash -s << 'EOF'

cd /var/ansible
ls -la

ansible-playbook /var/ansible/deploy_production.yml

EOF
