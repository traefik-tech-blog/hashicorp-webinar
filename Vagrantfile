# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SCRIPT
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
apt-get install docker-ce -y

# restart docker to make sure we get the latest version of the daemon if there is an upgrade
sudo service docker restart

# make sure we can actually use docker as the vagrant user
sudo usermod -aG docker vagrant

# install cni plugins https://www.nomadproject.io/docs/integrations/consul-connect#cni-plugins
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.0.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz

# install consul
apt-get install consul=1.10.1 -y

# config consul
IP_ADDRESS=$(ifconfig eth1 | grep -E -o "(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)" | head -n 1)

cat <<EOF >/tmp/consul-config
# Full configuration options can be found at https://www.consul.io/docs/agent/options.html
server = true
bootstrap_expect = 2
data_dir = "/opt/consul"
advertise_addr = "$IP_ADDRESS"
client_addr = "0.0.0.0"
retry_join = ["192.168.88.4", "192.168.88.5"]
connect {
  enabled = true
}
ports {
  grpc = 8502
  http = 8500
}
ui_config {
  enabled = true
}
EOF

mv /tmp/consul-config /etc/consul.d/consul.hcl
chown --recursive consul:consul /etc/consul.d
chmod 640 /etc/consul.d/consul.hcl

# start consul
sudo systemctl enable consul
sudo systemctl start consul
sudo systemctl status consul

# install nomad
apt-get install nomad=1.1.3 -y

cat <<EOF >/tmp/nomad-config
# Full configuration options can be found at https://www.nomadproject.io/docs/configuration
data_dir = "/opt/nomad"
leave_on_terminate = true
advertise {
  http = "$IP_ADDRESS"
  rpc  = "$IP_ADDRESS"
  serf = "$IP_ADDRESS"
}
client {
  enabled           = true
  network_interface = "eth1"

  host_volume "traefikee-data" {
    path = "/opt/traefikee"
    read_only = false
  }

  host_volume "traefikee-plugins" {
    path = "/opt/traefikee-plugins"
    read_only = false
  }
}
server {
  enabled          = true
  bootstrap_expect = 2
}
vault {
  enabled = true
  address = "http://192.168.88.4:8200"
  token   = "root"
}

EOF

mv /tmp/nomad-config /etc/nomad.d/nomad.hcl
chown --recursive nomad:nomad /etc/nomad.d
chmod 640 /etc/nomad.d/nomad.hcl

# start nomad
sudo systemctl enable nomad
sudo systemctl start nomad
sudo systemctl status nomad
# nomad -autocomplete-install not working

# install vault
apt-get install vault=1.8.1 -y

# create traefikee directories
sudo mkdir -p /opt/traefikee /opt/traefikee-plugins
SCRIPT

$vault = <<VAULT
vault server -dev -dev-listen-address="0.0.0.0:8200" -dev-root-token-id="root" > vault.log 2>&1 &
VAULT

Vagrant.configure("2") do |config|
  # Start from this base box
  config.vm.box = "hashicorp/bionic64"

  # Run the bootstrap script
  config.vm.provision "shell", inline: $script

  # Copy Nomad job files to host
  config.vm.provision "file", source: "jobs", destination: "jobs"
  config.vm.provision "file", source: "bundle.zip", destination: "bundle.zip"

  # Primary specific config
  config.vm.define "primary", primary: true do |primary|
    primary.vm.hostname = "traefik-webinar-1"
    primary.vm.network "private_network", ip: "192.168.88.4"

    # Increase memory for Virtualbox
    primary.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
    end

    # set up Vault
    primary.vm.provision "shell", inline: $vault

    # Expose the nomad api and ui to the host
    primary.vm.network "forwarded_port", guest: 4646, host: 4646, auto_correct: true, host_ip: "127.0.0.1"

    # Expose the consul api and ui to the host
    primary.vm.network "forwarded_port", guest: 8500, host: 8500, auto_correct: true, host_ip: "127.0.0.1"

    # Expose the vault api and ui to the host
    primary.vm.network "forwarded_port", guest: 8200, host: 8200, auto_correct: true, host_ip: "127.0.0.1"

    # Expose the traefik service ports to the host
    primary.vm.network "forwarded_port", guest: 80, host: 8080, auto_correct: true, host_ip: "127.0.0.1"
    primary.vm.network "forwarded_port", guest: 443, host: 8443, auto_correct: true, host_ip: "127.0.0.1"
    primary.vm.network "forwarded_port", guest: 9002, host: 9002, auto_correct: true, host_ip: "127.0.0.1"
  end

  # Secondary specific config
  config.vm.define "secondary", secondary: true do |secondary|
    secondary.vm.hostname = "traefik-webinar-2"
    secondary.vm.network "private_network", ip: "192.168.88.5"

    # Expose the traefik service ports to the host
    secondary.vm.network "forwarded_port", guest: 80, host: 8081, auto_correct: true, host_ip: "127.0.0.1"
    secondary.vm.network "forwarded_port", guest: 443, host: 8444, auto_correct: true, host_ip: "127.0.0.1"
  end
end
