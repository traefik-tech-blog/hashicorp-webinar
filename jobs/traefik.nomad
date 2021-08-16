job "traefik" {
  datacenters = ["dc1"]

  affinity {
    attribute = "${node.unique.name}"
    value     = "traefik-webinar-1"
    weight    = 100
  }

  group "traefik" {
    count = 1

    network {
      port "web" {
        static = 80
      }

      port "websecure" {
        static = 443
      }

      port "api" {
        static = 8081
      }
    }

    service {
      name = "traefik"
      port = "web"

      check {
        type     = "http"
        path     = "/ping"
        port     = "web"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name = "traefik-dashboard"
      port = "api"

      #      tags = [
      #        "traefik.enable=true",
      #        "traefik.http.routers.dashboard.rule=Path(`/dashboard`)",
      #      ]

      check {
        type     = "http"
        path     = "/"
        port     = "api"
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
  traefik:
    address: ":8081"

api:
  dashboard: true
  insecure: true

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

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
