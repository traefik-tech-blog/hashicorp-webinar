# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/bionic64"
  config.vm.hostname = "traefik-webinar"

  # Increase memory for Virtualbox
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end

  # Expose the nomad api and ui to the host
  config.vm.network "forwarded_port", guest: 4646, host: 4646, auto_correct: true, host_ip: "127.0.0.1"

  # Expose the consul api and ui to the host
  config.vm.network "forwarded_port", guest: 8500, host: 8500, auto_correct: true, host_ip: "127.0.0.1"

  # Expose the traefik service ports to the host
  config.vm.network "forwarded_port", guest: 80, host: 8080, auto_correct: true, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 443, host: 8443, auto_correct: true, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 9002, host: 9002, auto_correct: true, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 55055, host: 55055, auto_correct: true, host_ip: "127.0.0.1"

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

    # install cni plugins https://www.nomadproject.io/docs/integrations/consul-connect#cni-plugins
    curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.0.0.tgz
    sudo mkdir -p /opt/cni/bin
    sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz

    # install nomad
    apt-get install nomad=1.1.3 -y

    # set nomad to dev mode
    sudo sed -i 's|ExecStart.*|ExecStart=/usr/bin/nomad agent -dev-connect -config /home/vagrant/config/nomad.hcl|' /usr/lib/systemd/system/nomad.service

    # start nomad
    sudo systemctl enable nomad
    sudo systemctl start nomad
    sudo systemctl status nomad
    # nomad -autocomplete-install not working

    # install consul
    apt-get install consul=1.10.1 -y

    # set consul to dev mode
    sudo sed -i 's|ExecStart.*|ExecStart=/usr/bin/consul agent -dev -client 0.0.0.0 -ui|' /usr/lib/systemd/system/consul.service

    # start consul
    sudo systemctl enable consul
    sudo systemctl start consul
    sudo systemctl status consul

    # install vault
    apt-get install vault=1.8.1 -y

    # create traefikee directories
    sudo mkdir -p /opt/traefikee /opt/traefikee-plugins
  SHELL

  # Copy Nomad job files to host
  config.vm.provision "file", source: "jobs", destination: "jobs"
  config.vm.provision "file", source: "config", destination: "config"
  config.vm.provision "file", source: "bundle.zip", destination: "bundle.zip"

end
