job "faas-monitoring" {
  datacenters = ["dc1"]

  type = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  constraint {
    attribute = "${attr.cpu.arch}"
    operator  = "!="
    value     = "arm"
  }

  group "faas-monitoring" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "alertmanager" {
      driver = "docker"

      #artifact {
      #  source      = "https://raw.githubusercontent.com/hashicorp/faas-nomad/master/nomad_job_files/templates/alertmanager.yml"
      #  destination = "local/alertmanager.yml.tpl"
      #  mode        = "file"
      #}

      artifact {
        source      = "https://raw.githubusercontent.com/jahentao/faas-nomad-provider/master/nomad_job_files/templates/alertmanager.yml"
        destination = "local/alertmanager.yml.tpl"
          mode        = "file"
      }

      template {
        source        = "local/alertmanager.yml.tpl"
        destination   = "/etc/alertmanager/alertmanager.yml"
        change_mode   = "noop"
        change_signal = "SIGINT"
      }

      config {
        #image = "prom/alertmanager:v0.9.1"
        image = "prom/alertmanager:v0.20.0"

        port_map {
          http = 9093
        }

        dns_servers = ["${NOMAD_IP_http}", "8.8.8.8", "8.8.8.4"]

        #args = [
        #  "-config.file=/etc/alertmanager/alertmanager.yml",
        #  "-storage.path=/alertmanager",
        #]

        args = [
          "--config.file=/etc/alertmanager/alertmanager.yml",
          "--storage.path=/alertmanager",
        ]

        volumes = [
          "etc/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml",
        ]
      }

      resources {
        cpu    = 100 # 100 MHz
        memory = 128 # 128MB

        network {
          mbits = 10

          port "http" {}
        }
      }

      service {
        port = "http"
        name = "alertmanager"
        tags = ["faas"]
      }
    }

    task "prometheus" {
      driver = "docker"

      artifact {
        source      = "https://raw.githubusercontent.com/hashicorp/faas-nomad/master/nomad_job_files/templates/prometheus.yml"
        destination = "local/prometheus.yml.tpl"
        mode        = "file"
      }

      artifact {
        source      = "https://raw.githubusercontent.com/hashicorp/faas-nomad/master/nomad_job_files/templates/alert.rules"
        destination = "local/alert.rules.tpl"
        mode        = "file"
      }

      #artifact {
      #  source      = "https://github.com/jahentao/faas-nomad-provider/raw/master/nomad_job_files/templates/alert.rules.yml"
      #  destination = "local/alert.rules.tpl"
      #  mode        = "file"
      #}

      template {
        source        = "local/prometheus.yml.tpl"
        destination   = "/etc/prometheus/prometheus.yml"
        change_mode   = "noop"
        change_signal = "SIGINT"
      }

      template {
        source        = "local/alert.rules.tpl"
        destination   = "/etc/prometheus/alert.rules"
        change_mode   = "noop"
        change_signal = "SIGINT"
      }

      config {
        image = "prom/prometheus:v1.5.2"
        #image = "prom/prometheus:v2.15.2"

        args = [
          "-config.file=/etc/prometheus/prometheus.yml",
          "-storage.local.path=/prometheus",
          "-storage.local.memory-chunks=10000",
        ]

        #args = [
        #  "--config.file=/etc/prometheus/prometheus.yml",
        #]

        dns_servers = ["${NOMAD_IP_http}", "8.8.8.8", "8.8.8.4"]

        port_map {
          http = 9090
        }

        volumes = [
          "etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml",
          "etc/prometheus/alert.rules:/etc/prometheus/alert.rules",
        ]
      }

      resources {
        cpu    = 200 # 200 MHz
        memory = 256 # 256MB

        network {
          mbits = 10

          port "http" {
            static = 9090
          }
        }
      }

      service {
        port = "http"
        name = "prometheus"
        tags = ["faas"]

        check {
          type     = "http"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
          path     = "/graph"
        }
      }
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:6.6.0"

        port_map {
          http = 3000
        }
      }

      resources {
        cpu    = 200 # 500 MHz
        memory = 256 # 256MB

        network {
          mbits = 10

          port "http" {
            static = 3000
          }
        }
      }
    }
  }
}
