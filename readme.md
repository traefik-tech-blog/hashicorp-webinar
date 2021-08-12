# Simplifying Infrastructure and Networking Automation with HashiCorp and Traefik

Insert summary blurb here about what this is webinar / blog / demo / etc

## Getting Started

You can use Vagrant to set up the lab environment used in this webinar. Vagrant is
a tool for building and managing virtual machine environments.

~> **NOTE**: To use the Vagrant environment, first install Vagrant following
these [instructions](https://www.vagrantup.com/docs/installation/). You also
need a virtualization tool, such as [VirtualBox](https://www.virtualbox.org/).

From a terminal in this folder, you may create the virtual machine with the `vagrant up` command.

```shell-session
$ vagrant up
```

This takes a few minutes as the base Ubuntu box must be downloaded
and provisioned with Docker, Nomad, and Consul. Once this completes, you should see this output.

```plaintext hideClipboard
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'bento/ubuntu-18.04'...
...
==> default: Running provisioner: docker...
```

Once this provisioning completes, use the `vagrant ssh` command to start a shell session on it.

```shell-session
$ vagrant ssh
```

If you connect to the virtual machine properly, you should find yourself at a
shell prompt for `vagrant@traefik-webinar:~$`

Please note that in this lab environment Nomad, Consul, and Vault are configured in `dev` mode. This mode is useful for developing or testing because it doesn't require any extra configuration, and does not persist any state to disk.

!! Warning: Never run -dev mode in production.

## Accessing the environment

You may view the Nomad and Consul interfaces with a web browser. Please access here:
- Nomad UI http://localhost:4646/
- Consul UI http://localhost:8500/

## Demo

### Nomad

### Consul

#### Consul Catalog

```bash
nomad job run jobs/whoami.nomad
nomad job run jobs/traefik.nomad

nomad status

curl localhost/whoami
```

Visit http://localhost:8080/whoami from your desktop. Take note of the value `RemoteAddr`.

#### Consul Connect

```bash
nomad job run jobs/whoami-connect.nomad

nomad status

curl localhost/whoami
```

Visit http://localhost:8080/whoami from your desktop. Take note of the value `RemoteAddr`. What is it now? What was it before? What's changed and why?

### Vault

#### PKI

```bash
# Enable Vault PKI and create role
export VAULT_ADDR=http://127.0.0.1:8200

vault secrets enable pki

vault write pki/root/generate/internal common_name="VAULT PKI CERT"
vault write pki/roles/traefikee allowed_domains=localhost allow_bare_domains=true allow_subdomains=true max_ttl=10h
```

#### KV Store

```bash
# generate self-signed certificate
# TODO

# Add TLS cert to Vault KV store
vault kv put secret/traefik.localhost cert="$(cat cert.pem | base64 -w0)" key="$(cat key.pem | base64 -w0)"
```

## Cleaning up

### Halt the VM

Exit any shell sessions that you made to the virtual machine. Use the `vagrant halt` command to stop the
running VM.

```shell-session
$ vagrant halt
```

At this point, you can start the VM again without having to provision it.

### De-provision the VM

If you don't anticipate using the training VM for a while, and don't mind the
time necessary to provision it, you can deprovision the VM. From this folder, use the `vagrant destroy` command to
deprovision the environment your created. The command verifies that you intend
to perform this activity; enter `Y` to confirm that you do.

```shell-session
$ vagrant destroy
```

```plaintext
    default: Are you sure you want to destroy the 'default' VM? [y/N] y
==> default: Forcing shutdown of VM...
==> default: Destroying VM and associated drives...
```

De-provisioning the environment deletes the VM that is created based on the base
box.

### Remove the base box

If you don't intend to use the Vagrant environment ever again, you can also
delete the downloaded Vagrant base box used to create the VM by running the
`vagrant box remove` command. Don't worry, if you decide to use the environment
again later, Vagrant re-downloads the base box when you need it.

```shell-session
$ vagrant box remove bento/ubuntu-18.04
```

```plaintext
Removing box 'bento/ubuntu-18.04' (v202008.16.0) with provider 'virtualbox'...
```

At this point, you have removed all of the parts that are added by starting up
the Vagrantfile.

## Documentation and References
- [Traefik](https://doc.traefik.io/traefik/)
- [Introduction to Consul](https://learn.hashicorp.com/tutorials/consul/get-started?in=consul/getting-started)
- [Introduction to Vault](https://learn.hashicorp.com/tutorials/vault/getting-started-intro?in=vault/getting-started)
- [Introduction to Nomad](https://learn.hashicorp.com/tutorials/nomad/get-started-intro?in=nomad/get-started)
