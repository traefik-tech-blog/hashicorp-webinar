job "countdash" {
  datacenters = ["dc1"]

  group "api" {
    network {
      mode = "bridge"
    }

    service {
      name = "count-api"
      port = "9001"

      connect {
        sidecar_service {}
      }
    }

    task "web" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-api:v3"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }

  group "dashboard" {
    network {
      mode = "bridge"

      port "http" {
        to = 9002
      }
    }

    service {
      name = "count-dashboard"
      port = "9002"

      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.countdash.rule=Host(`countdash.localhost`)",
      ]

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "count-api"
              local_bind_port  = 8080
            }
          }
        }
      }
    }

    task "dashboard" {
      driver = "docker"

      env {
        COUNTING_SERVICE_URL = "http://${NOMAD_UPSTREAM_ADDR_count_api}"
      }

      config {
        image = "hashicorpnomad/counter-dashboard:v3"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
