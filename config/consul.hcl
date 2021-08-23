# Full configuration options can be found at https://www.consul.io/docs/agent/options.html
data_dir = "/opt/consul"

server           = true
bootstrap_expect = 2
advertise_addr   = "{{ GetInterfaceIP `eth1` }}"
client_addr      = "0.0.0.0"
retry_join       = ["192.168.88.4", "192.168.88.5"]

datacenter = "dc1"

connect {
  enabled = true
}

ports {
  grpc = 8502
}

ui_config {
  enabled = true
}
