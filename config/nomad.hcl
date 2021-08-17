client {
  host_volume "traefikee-data" {
    path = "/opt/traefikee"
    read_only = false
  }

  host_volume "traefikee-plugins" {
    path = "/opt/traefikee-plugins"
    read_only = false
  }
}

vault {
  enabled = true
  address = "http://127.0.0.1:8200"
  token   = "root"
}
