# Simplifying Infrastructure and Networking Automation with HashiCorp and Traefik

## Nomad

```bash
vagrant up

vagrant scp traefik/traefik.nomad /home/vagrant/
vagrant scp whoami/whoami.nomad /home/vagrant/

vagrant ssh

# start processes in vagrant VM
sudo nomad agent -dev-connect > nomad.log 2>&1 &
consul agent -dev > consul.log 2>&1 &
vault server -dev > vault.log 2>&1 &
```

## Consul

### Consul Catalog

```bash
nomad run whoami.nomad
nomad run traefik.nomad

nomad status

curl localhost/whoami
```

### Consul Connect

```bash
# TODO
```

## Vault

### PKI

```bash
# Enable Vault PKI and create role
export VAULT_ADDR=http://127.0.0.1:8200

vault secrets enable pki

vault write pki/root/generate/internal common_name="VAULT PKI CERT"
vault write pki/roles/traefikee allowed_domains=localhost allow_bare_domains=true allow_subdomains=true max_ttl=10h
```

### KV Store

```bash
# generate self-signed certificate
# TODO

# Add TLS cert to Vault KV store
vault kv put secret/traefik.localhost cert="$(cat cert.pem | base64 -w0)" key="$(cat key.pem | base64 -w0)"
```
