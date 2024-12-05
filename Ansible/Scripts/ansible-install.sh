#!/usr/bin/env bash
# ------------------------------------------------------------------------
# Bash script for a complete Ansible installation
#
# Supported distributions:
#   - Fedora 20 and greater
#   - CentOS 7 and 8
#   - Ubuntu 18.04, 20.04, 22.04
#
# Updated by Brent WG
# ------------------------------------------------------------------------

LOG_FILE="/var/log/ansible_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ----------------
# Script Functions
# ----------------
error_exit() {
  echo ""
  echo "ERROR: $PRETTY_NAME is not supported by this script."
  echo
  exit 1
}

check_prerequisites() {
  echo "Checking prerequisites..."
  for cmd in curl wget sudo; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "ERROR: $cmd is required but not installed. Please install it first."
      exit 1
    fi
  done
}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root. Use sudo."
    exit 1
  fi
}

check_ansible_installed() {
  echo "Checking if Ansible is already installed..."
  if command -v ansible >/dev/null 2>&1; then
    echo "Ansible is already installed."
    exit 0
  fi
}

install_packages() {
  local packages=("$@")
  echo "Installing packages: ${packages[*]}..."
  case "$ID" in
    ubuntu|debian)
      sudo apt-get install -y "${packages[@]}"
      ;;
    fedora)
      sudo dnf install -y "${packages[@]}"
      ;;
    centos)
      sudo yum install -y "${packages[@]}"
      ;;
  esac
}

install_ansible() {
  echo "Installing Ansible on $PRETTY_NAME..."
  case "$ID" in
    ubuntu|debian)
      sudo apt-get update
      sudo apt-get install -y software-properties-common
      sudo apt-add-repository --yes --update ppa:ansible/ansible
      install_packages ansible
      ;;
    fedora)
      if [ "$VERSION_ID" -ge 20 ]; then
        install_packages ansible
      else
        error_exit
      fi
      ;;
    centos)
      case "$VERSION_ID" in
        7|8)
          install_packages epel-release ansible
          ;;
        *)
          error_exit
          ;;
      esac
      ;;
    *)
      error_exit
      ;;
  esac
}

configure_ansible() {
  echo "Configuring Ansible..."
  mkdir -p ~/.ansible
  cat <<EOF > ~/.ansible/ansible.cfg
[defaults]
inventory = ./hosts
host_key_checking = False
retry_files_enabled = False
EOF
}

create_inventory_file() {
  echo "Creating a default Ansible inventory file..."
  cat <<EOF > ./hosts
[local]
localhost ansible_connection=local
EOF
}

install_optional_dependencies() {
  echo "Installing optional dependencies..."
  install_packages python3 python3-pip sshpass
}

verify_ansible_installation() {
  echo "Verifying Ansible installation..."
  ansible --version
}

install_ansible_roles() {
  echo "Installing common Ansible roles..."
  ansible-galaxy install geerlingguy.mysql geerlingguy.apache
}

# -----------------
# Main Script Logic
# -----------------
echo "Starting Ansible bootstrap process..."
require_root
check_prerequisites
check_ansible_installed

echo "Detecting OS version..."
. /etc/os-release

echo "Installing Ansible for $PRETTY_NAME..."
install_ansible

install_optional_dependencies
configure_ansible
create_inventory_file
install_ansible_roles
verify_ansible_installation

echo "Ansible installation and setup completed successfully!"
