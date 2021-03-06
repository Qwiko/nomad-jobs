job "traefik" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1
    update {
      max_parallel = 1
    }
    network {
      port "http" {
        static = 80
      }

      port "api" {
        static = 8081
      }
    }

    service {
      name = "traefik"
      port = "api"
      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v2.2"
        network_mode = "host"
        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[entryPoints]
    [entryPoints.http]
    address = ":80"
    [entryPoints.https]
    address = ":443"
    [entryPoints.traefik]
    address = ":8081"
[accessLog]

[api]
    dashboard = true
    insecure  = true

[metrics]
  [metrics.prometheus]
    addEntryPointsLabels = true
    addServicesLabels = true

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
    prefix           = "traefik"
    exposedByDefault = true
    defaultRule      = "Host(`{{"{{.Name }}"}}.service.consul`)  || Host(`{{"{{.Name }}"}}.service`) || Host(`{{"{{.Name }}"}}.service.admin.pingstmellanbygden.se`)"

    [providers.consulCatalog.endpoint]
      address = "127.0.0.1:8500"
      scheme  = "http"
EOF

        destination = "local/traefik.toml"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}