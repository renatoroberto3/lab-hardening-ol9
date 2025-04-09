#!/bin/bash
#script cria a base do projeto de hardening, pode ser usado apenas local ou repositório no git
# nome do dir pode ser o nome do repo remoto pra facilitar
base_dir="REPO-BASE"

# Create the base directory if it doesn't exist
mkdir -p "$base_dir"

# Principais subdirs
mkdir -p "$base_dir/inventory/"
mkdir -p "$base_dir/playbooks"
mkdir -p "$base_dir/roles/audit/tasks"
mkdir -p "$base_dir/roles/remediation/tasks"

# Principais arquivos
touch "$base_dir/ansible.cfg"
touch "$base_dir/AUDIT.log"
touch "$base_dir/README.md"
touch "$base_dir/inventory/hosts"
touch "$base_dir/playbooks/audit.yml"
touch "$base_dir/playbooks/remediation.yml"

# Create the tasks main files
touch "$base_dir/roles/audit/tasks/main.yml"
touch "$base_dir/roles/remediation/tasks/main.yml"

echo "Estrutura de diretórios e arquivos criado com sucesso dentro de '$base_dir'!"
