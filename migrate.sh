#!/bin/bash

# Parse variables from the local environment.yml file
REMOTE_HOST=$(yq eval '.vm_ip' environment.yml)
REMOTE_USER=$(yq eval '.vm_user' environment.yml)
REMOTE_PASSWORD=$(yq eval '.vm_password' environment.yml)


# Upload SSH private key for Git operations
sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no "$LOCAL_SSH_PRIVATE_KEY_PATH" "$REMOTE_USER@$REMOTE_HOST:/tmp/private_key"
sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no "$LOCAL_MYSQL_PRIVATE_KEY_PATH" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_MYSQL_PRIVATE_KEY_PATH"

# Install Ansible, Git, clone the repository, and clean up
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" GIT_REPO_URL="$GIT_REPO_URL" bash -s << 'EOF'
EOF

# Upload environment.yml from the local machine to the remote VM
sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no "$SCRIPT_DIR/environment.yml" "$REMOTE_USER@$REMOTE_HOST:/var/ansible/"

# Connect to the VM and run multiple commands
sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" bash -s << 'EOF'

ansible-playbook /var/ansible/migrate.yml

EOF
