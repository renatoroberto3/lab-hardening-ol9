#!/bin/bash
#script cria a base do projeto de hardening, pode ser usado apenas local ou repositório no git
# Define the base directory name
base_dir="REPO-BASE"

# Create the base directory if it doesn't exist
mkdir -p "$base_dir"

# Create the main directories inside the base directory
mkdir -p "$base_dir/playbooks"
mkdir -p "$base_dir/inventory"
mkdir -p "$base_dir/roles"

# Create the subdirectory in inventory
mkdir -p "$base_dir/inventory/hosts"

# Create the files
touch "$base_dir/ansible.cfg"
touch "$base_dir/AUDIT.log"
touch "$base_dir/README.md"

# Create the playbooks
touch "$base_dir/playbooks/audit.yml"
touch "$base_dir/playbooks/remediation.yml"

# Create the roles directories
mkdir -p "$base_dir/roles/audit"
mkdir -p "$base_dir/roles/hardening"
mkdir -p "$base_dir/roles/remediation"

echo "Esqueleto de diretórios e arquivos criado com sucesso dentro de '$base_dir'!"
