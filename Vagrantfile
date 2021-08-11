# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/bionic64"

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

    # install consul
    apt-get install consul -y

    # install vault
    apt-get install vault -y

  SHELL
end
