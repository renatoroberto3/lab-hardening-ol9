Vagrant.configure("2") do |config|
  # Configurações globais
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  # Função para provisionamento comum
  def provision_common(vm)
    vm.vm.provision "shell", inline: <<-SHELL
      echo "Configurando a máquina..."
      dnf update -y || apt-get update -y
      dnf install -y openssh-server ansible neofetch htop vim lynis git || apt-get install -y ansible git
      timedatectl set-timezone America/Sao_Paulo || timedatectl set-timezone America/Sao_Paulo
      echo "Máquina configurada."
    SHELL
  end

  # --- Máquina Debian (Host Ansible) ---
  config.vm.define "debian_host" do |debian|
    debian.vm.box = "generic/debian12"
    debian.vm.hostname = "debian-host"
    debian.vm.network "private_network", ip: "192.168.213.11", virtualbox__intnet: "vboxnet0"
    debian.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
    end
    provision_common(debian)

    # Provisionamento específico para executar o script
    debian.vm.provision "shell", inline: <<-SHELL
      echo "Executando o script gera-repobase.sh..."
      chmod +x /vagrant/gera-repobase.sh
      /vagrant/gera-repobase.sh
      echo "Script gera-repobase.sh concluído."
    SHELL
  end

  # --- Máquina Oracle Linux 9 (Máquina Alvo 1) ---
  config.vm.define "oracle9-1" do |oracle1|
    oracle1.vm.box = "generic/oracle9"
    oracle1.vm.hostname = "oracle9-1"
    oracle1.vm.network "private_network", ip: "192.168.213.12", virtualbox__intnet: "vboxnet0"
    provision_common(oracle1)
  end

  # --- Máquina Oracle Linux 9 (Máquina Alvo 2) ---
  config.vm.define "oracle9-2" do |oracle2|
    oracle2.vm.box = "generic/oracle9"
    oracle2.vm.hostname = "oracle9-2"
    oracle2.vm.network "private_network", ip: "192.168.213.13", virtualbox__intnet: "vboxnet0"
    provision_common(oracle2)
  end

  # --- Sincronizar a chave SSH ---
  config.vm.synced_folder "C:/Users/USER1/.ssh", "/vagrant/.ssh", create: true

  # --- Configurações SSH para acesso direto ---
  config.ssh.private_key_path = 'C:/Users/USER1/.ssh/id_rsa_ora9'
  config.ssh.insert_key = false

  # --- Configurações SSH específicas por máquina ---
  config.vm.provision "file", source: "C:/Users/USER1/.ssh/id_rsa_ora9", destination: "~/.ssh/id_rsa", owner: "vagrant", group: "vagrant", mode: "0600", only_if: "test -d /home/vagrant/.ssh"
  config.vm.provision "shell", inline: "chmod 600 ~/.ssh/id_rsa", only_if: "test -f ~/.ssh/id_rsa"
end
