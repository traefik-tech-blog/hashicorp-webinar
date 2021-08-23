# Full configuration options can be found at https://www.nomadproject.io/docs/configuration
data_dir = "/opt/nomad"

leave_on_terminate = true

advertise {
  http = "{{ GetInterfaceIP `eth1` }}"
  rpc  = "{{ GetInterfaceIP `eth1` }}"
  serf = "{{ GetInterfaceIP `eth1` }}"
}

client {
  enabled           = true
  network_interface = "eth1"

  host_volume "traefikee-data" {
    path      = "/opt/traefikee"
    read_only = false
  }

  host_volume "traefikee-plugins" {
    path      = "/opt/traefikee-plugins"
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
}
