#!/bin/bash

# Set default Ansible directory
BASE_DIR="/home/mark/ansible"

# Ensure base directory exists
mkdir -p "$BASE_DIR"
cd "$BASE_DIR" || exit

# Create ansible.cfg
cat <<EOL > ansible.cfg
[defaults]
inventory = ./inventory
remote_user = ansible
private_key_file = ~/.ssh/id_rsa
host_key_checking = False
retry_files_enabled = False
EOL

# Create inventory directories and files
mkdir -p inventory
cat <<EOL > inventory/development
[webservers]
web1 ansible_host=192.168.1.10 ansible_user=ubuntu

[dbservers]
db1 ansible_host=192.168.1.20 ansible_user=ubuntu
EOL

touch inventory/staging inventory/production

# Create group_vars and host_vars
mkdir -p group_vars host_vars

cat <<EOL > group_vars/all.yml
---
timezone: "UTC"
ntp_servers:
  - "0.pool.ntp.org"
  - "1.pool.ntp.org"
EOL

cat <<EOL > host_vars/host1.yml
---
custom_hostname: "web1"
EOL

# Create roles directory structure
mkdir -p roles/common/{tasks,handlers,templates,files,vars,defaults,meta}
cat <<EOL > roles/common/tasks/main.yml
---
- name: Ensure latest apt cache
  apt:
    update_cache: yes

- name: Install essential packages
  apt:
    name:
      - git
      - curl
    state: present
EOL

touch roles/common/handlers/main.yml
touch roles/common/templates/.gitkeep
touch roles/common/files/.gitkeep

cat <<EOL > roles/common/vars/main.yml
---
# Role-specific variables
EOL

cat <<EOL > roles/common/defaults/main.yml
---
# Default variables
EOL

cat <<EOL > roles/common/meta/main.yml
---
# Role metadata
dependencies: []
EOL

# Create playbooks directory and playbooks
mkdir -p playbooks
cat <<EOL > playbooks/site.yml
---
- name: Configure all servers
  hosts: all
  roles:
    - common
EOL

cat <<EOL > playbooks/webservers.yml
---
- name: Configure webservers
  hosts: webservers
  roles:
    - common
EOL

cat <<EOL > playbooks/dbservers.yml
---
- name: Configure dbservers
  hosts: dbservers
  roles:
    - common
EOL

# Create README.md
cat <<EOL > README.md
# Ansible Project

## Description
This project is a boilerplate for setting up an Ansible project following best practices.

## Structure
- **ansible.cfg**: Ansible configuration file.
- **inventory/**: Contains inventory files for different environments.
- **group_vars/**: Variables applied to host groups.
- **host_vars/**: Variables specific to individual hosts.
- **roles/**: Reusable roles with tasks, handlers, templates, and more.
- **playbooks/**: High-level playbooks orchestrating role execution.

## Usage
1. Modify the inventory files with your host details.
2. Customize group_vars and host_vars as needed.
3. Run a playbook:
   \`\`\`
   ansible-playbook playbooks/site.yml
   \`\`\`
EOL

echo "Ansible project structure has been created successfully in $BASE_DIR."
