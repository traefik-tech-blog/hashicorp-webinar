job "traefikee" {
  datacenters = ["dc1"]

  group "controllers" {
    count = 1

    affinity {
      attribute = "${node.unique.name}"
      value     = "traefik-webinar-1"
      weight    = 100
    }

    network {
      mode = "host"

      port "control" {
        static = 4242
      }

      port "api" {
        static = 55055
      }
    }

    service {
      name = "traefikee-controllers"

      check {
        failures_before_critical = 2
        interval                 = "30s"
        port                     = "control"
        timeout                  = "5s"
        type                     = "tcp"
      }

      port = "control"

      task = "controllers"
    }

    task "controllers" {
      driver = "docker"

      config {
        image = "traefik/traefikee:latest"

        args = [
          "controller",
          "--name=${NOMAD_ALLOC_NAME}",
          "--advertise=${NOMAD_ADDR_control}",
          "--discovery.static.peers=${NOMAD_ADDR_control}",
          "--license=${TRAEFIKEE_LICENSE}",
          "--statedir=/data",
          "--jointoken.file.path=/data/tokens",
          "--api.bundle=/data/bundle.zip",
          "--socket=${NOMAD_TASK_DIR}/cluster.sock",
          "--api.socket=${NOMAD_TASK_DIR}/api.sock",
          "--plugin.token=${PLUGIN_TOKEN}",
          "--plugin.url=https://192.168.88.5:8443",
        ]

        cap_add = ["NET_BIND_SERVICE"]

        cap_drop = ["ALL"]

        network_mode = "host"

        ports = ["control", "api"]
      }

      resources {
        cpu    = 500
        memory = 256
      }

      template {
        data = <<EOF
TRAEFIKEE_LICENSE="{{with secret "secret/traefikee/license"}}{{.Data.data.license_key}}{{end}}"
PLUGIN_TOKEN="{{with secret "secret/traefikee/plugin"}}{{.Data.data.token}}{{end}}"
EOF

        destination = "secrets/traefikee.env"
        env         = true
      }

      volume_mount {
        destination = "/data"
        volume      = "data"
      }
    }

    volume "data" {
      source = "traefikee-data"
      type   = "host"
    }
  }

  group "proxies" {
    count = 2

    network {
      mode = "host"

      port "distributed" {
        static = 8484
      }

      port "web" {
        static = 80
      }

      port "websecure" {
        static = 443
      }
    }

    service {
      name = "traefikee-proxies"

      port = "web"

      task = "proxies"
    }

    task "proxies" {
      driver = "docker"

      config {
        image = "traefik/traefikee:latest"

        args = [
          "proxy",
          "--discovery.static.peers=192.168.88.4:4242",
          "--jointoken.value=${PROXY_JOIN_TOKEN}",
        ]

        cap_add = ["NET_BIND_SERVICE"]

        cap_drop = ["ALL"]

        dns_servers = [
          "127.0.0.1",
          "${attr.unique.network.ip-address}",
          "8.8.8.8",
        ]

        network_mode = "host"

        ports = ["distributed", "web", "websecure"]
      }

      resources {
        cpu    = 500
        memory = 256
      }

      template {
        data = <<EOF
PROXY_JOIN_TOKEN="{{with secret "secret/traefikee/proxy"}}{{.Data.data.token}}{{end}}"
EOF

        destination = "secrets/traefikee.env"
        env         = true
      }
    }
  }

  group "plugin-registry" {
    count = 1

    affinity {
      attribute = "${node.unique.name}"
      value     = "traefik-webinar-2"
      weight    = 100
    }

    network {
      mode = "host"

      port "https" {
        static = 8443
      }
    }

    service {
      name = "traefikee-plugin-registry"

      port = "https"

      task = "plugin-registry"
    }

    task "plugin-registry" {
      driver = "docker"

      config {
        image = "traefik/traefikee:latest"

        args = [
          "plugin-registry",
          "--addr=:8443",
          "--discovery.static.peers=192.168.88.4:4242",
          "--jointoken.value=${PROXY_JOIN_TOKEN}",
          "--plugindir=/data/plugins/",
          "--token=${PLUGIN_TOKEN}",
        ]

        cap_add = ["NET_BIND_SERVICE"]

        cap_drop = ["ALL"]

        dns_servers = [
          "127.0.0.1",
          "${attr.unique.network.ip-address}",
          "8.8.8.8",
        ]

        network_mode = "host"

        ports = ["https"]
      }

      resources {
        cpu    = 500
        memory = 256
      }

      template {
        data = <<EOF
PROXY_JOIN_TOKEN="{{with secret "secret/traefikee/proxy"}}{{.Data.data.token}}{{end}}"
PLUGIN_TOKEN="{{with secret "secret/traefikee/plugin"}}{{.Data.data.token}}{{end}}"
EOF

        destination = "secrets/traefikee.env"
        env         = true
      }

      volume_mount {
        destination = "/data/plugins"
        volume      = "plugins"
      }
    }

    volume "plugins" {
      source = "traefikee-plugins"
      type   = "host"
    }
  }

  update {
    max_parallel = 1
    stagger      = "30s"
  }
}
