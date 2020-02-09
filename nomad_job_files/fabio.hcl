job "fabio" {
  datacenters = ["dc1"]

  type = "system"

  constraint {
    attribute = "${attr.cpu.arch}"
    operator  = "="
    value     = "amd64"
  }

  group "fabio" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "fabio" {
      driver = "docker"
      
      env = {
        registry.consul.addr = "${NOMAD_IP_http}:8500"
      }

      template {
        env = true
        destination   = "secrets/fabio.env"

        data = <<EOH
registry.consul.addr="{{ env "NOMAD_IP_http" }}:8500"
EOH
      }

      config {
        image = "magiconair/fabio:1.5.13-go1.13.4"

        port_map {
          http = 9999
          admin = 9998
        }

      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB

        network {
          mbits = 10

          port "admin" {
           static = 9998
          }

          port "http" {
            static = 80
          }
        }
      }

      service {
        port = "admin"
        name = "faasd-fabio"
        tags = ["faas"]

        check {
          name     = "alive"
          type     = "http"
          interval = "10s"
          timeout  = "2s"
          path     = "/health"
        }
      }
    }
  }
}
