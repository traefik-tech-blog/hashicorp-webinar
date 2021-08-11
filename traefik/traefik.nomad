job "traefik" {
  datacenters = ["dc1"]

  group "traefik" {
    count = 1

    network {
      port "web" {
        static = 80
      }

      port "websecure" {
        static = 443
      }
    }

    service {
      name = "traefik"

      check {
        type     = "http"
        path     = "/ping"
        port     = "web"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v2.5"
        network_mode = "host"

        volumes = [
          "local/traefik.yaml:/etc/traefik/traefik.yaml",
        ]
      }

      template {
        data = <<EOF
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

api:
  dashboard: true

ping:
  entryPoint: "web"

providers:
  consulCatalog:
    prefix: "traefik"
    exposedByDefault: false
    endpoint:
      address: "127.0.0.1:8500"
      scheme: "http"
    connectAware: true
EOF

        destination = "local/traefik.yaml"
      }

    }
  }
}
