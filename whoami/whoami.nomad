job "whoami" {
  datacenters = ["dc1"]

  group "whoami" {
    count = 2

    network {
      port "web" {}
    }

    service {
      name = "whoami"
      port = "web"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.whoami.rule=Path(`/whoami`)",
      ]

      check {
        type     = "http"
        path     = "/health"
        port     = "web"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "whoami" {
      driver = "docker"

      config {
        image = "traefik/whoami"
        ports = ["web"]
        args  = ["--port", "${NOMAD_PORT_web}"]
      }
    }
  }
}
