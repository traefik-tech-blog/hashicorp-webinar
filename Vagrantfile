# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/bionic64"

  # Increase memory for Virtualbox
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1536"
  end

  # Expose the nomad api and ui to the host
  config.vm.network "forwarded_port", guest: 4646, host: 4646, auto_correct: true, host_ip: "127.0.0.1"

  # Expose the consul api and ui to the host
  config.vm.network "forwarded_port", guest: 8500, host: 8500, auto_correct: true, host_ip: "127.0.0.1"

  # Expose the traefik service ports to the host
  config.vm.network "forwarded_port", guest: 80, host: 8080, auto_correct: true, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 443, host: 8443, auto_correct: true, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 9002, host: 9002, auto_correct: true, host_ip: "127.0.0.1"

  config.vm.provision "shell", inline: <<-SHELL
    # add HashiCorp GPG key and repo
    curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
     apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    apt-get update

    # add Docker GPG key and repo
    apt-get install apt-transport-https ca-certificates curl gnupg lsb-release -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update

    # install docker
    apt-get install docker-ce docker-ce-cli containerd.io -y

    # install nomad
    apt-get install nomad -y
    # nomad -autocomplete-install not working

    # install consul
    apt-get install consul -y

    # install vault
    apt-get install vault -y

    # install cni plugins https://www.nomadproject.io/docs/integrations/consul-connect#cni-plugins
    curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.0.0.tgz
    sudo mkdir -p /opt/cni/bin
    sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz
  SHELL

  # Copy Nomad job files
  config.vm.provision "file", source: "jobs", destination: "jobs"

end
