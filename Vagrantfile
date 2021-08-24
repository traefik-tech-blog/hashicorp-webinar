# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SCRIPT
echo "Adding HashiCorp GPG key and repo..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
 apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update

echo "Adding Docker GPG key and repo..."
apt-get install apt-transport-https ca-certificates curl jq gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

echo "Installing Docker..."
apt-get install docker-ce -y

# restart docker to make sure we get the latest version of the daemon if there is an upgrade
sudo service docker restart

# make sure we can actually use docker as the vagrant user
sudo usermod -aG docker vagrant

# install cni plugins https://www.nomadproject.io/docs/integrations/consul-connect#cni-plugins
echo "Installing cni plugins..."
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.0.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz

echo "Installing Consul..."
apt-get install consul=1.10.1 -y

# config consul
mv /tmp/consul.hcl /etc/consul.d/consul.hcl
chown --recursive consul:consul /etc/consul.d
chmod 640 /etc/consul.d/consul.hcl

# start consul
sudo systemctl enable consul
sudo systemctl start consul
sudo systemctl status consul

echo "Installing Nomad..."
apt-get install nomad=1.1.3 -y

# config nomad
mv /tmp/nomad.hcl /etc/nomad.d/nomad.hcl
chown --recursive nomad:nomad /etc/nomad.d
chmod 640 /etc/nomad.d/nomad.hcl

# provide vault token to nomad hosts
sudo tee -a /etc/nomad.d/nomad.env <<EOF
VAULT_TOKEN=root
EOF

# start nomad
sudo systemctl enable nomad
sudo systemctl start nomad
sudo systemctl status nomad

echo "Installing Vault..."
apt-get install vault=1.8.1 -y

# create traefikee directories
sudo mkdir -p /opt/traefikee /opt/traefikee-plugins

# configuring environment
sudo -H -u vagrant nomad -autocomplete-install
sudo -H -u vagrant consul -autocomplete-install
sudo -H -u vagrant vault -autocomplete-install
sudo tee -a /etc/environment <<EOF
export VAULT_ADDR=http://192.168.88.4:8200
export VAULT_TOKEN=root
EOF

source /etc/environment
SCRIPT

$vault = <<VAULT
echo "Starting Vault dev server..."
vault server -dev -dev-listen-address="0.0.0.0:8200" -dev-root-token-id="root" > vault.log 2>&1 &
sleep 5
vault status

# enable vault audit logs
touch /var/log/vault_audit.log
vault audit enable file file_path=/var/log/vault_audit.log
VAULT

$consul = <<CONSUL
echo "Creating an intention..."
consul intention create -deny traefik '*'
CONSUL

Vagrant.configure("2") do |config|
  # Start from this base box
  config.vm.box = "hashicorp/bionic64"

  # Copy Consul and Nomad configs to host
  config.vm.provision "file", source: "config", destination: "/tmp"

  # Run the bootstrap script
  config.vm.provision "shell", inline: $script

  # Copy Nomad job files to host
  config.vm.provision "file", source: "jobs", destination: "jobs"

  # Copy TraefikEE bundle to host (uncomment the next line once you have a bundle.zip)
  # config.vm.provision "file", source: "bundle.zip", destination: "bundle.zip"

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
  end

  # Secondary specific config
  config.vm.define "secondary", secondary: true do |secondary|
    secondary.vm.hostname = "traefik-webinar-2"
    secondary.vm.network "private_network", ip: "192.168.88.5"

    # Expose the traefik service ports to the host
    secondary.vm.network "forwarded_port", guest: 80, host: 8081, auto_correct: true, host_ip: "127.0.0.1"
    secondary.vm.network "forwarded_port", guest: 443, host: 8444, auto_correct: true, host_ip: "127.0.0.1"

    # set up Consul
    secondary.vm.provision "shell", inline: $consul
  end
end
