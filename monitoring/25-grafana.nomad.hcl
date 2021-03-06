job "grafana" {
  datacenters = ["dc1"]
  type        = "service"

  group "grafana" {
    count = 1

    network {
      dns {
        servers = ["192.168.10.20"]
      }
      port "http" {
        static = 3000
      }
    }
    restart {
      attempts = 3
      delay    = "20s"
      mode     = "delay"
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana"
        ports = ["http"]
        volumes = [
          "/home/nomad/grafana:/var/lib/grafana"
        ]
      }

      env {
        GF_LOG_LEVEL          = "DEBUG"
        GF_LOG_MODE           = "console"
        GF_SERVER_HTTP_PORT   = "${NOMAD_PORT_http}"
        GF_PATHS_PROVISIONING = "/local/grafana/provisioning"
      }

      template {
        data        = <<EOTC
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus.service.consul:9090
    jsonData:
      exemplarTraceIdDestinations:
      - name: traceID
        datasourceUid: tempo
  - name: Tempo
    type: tempo
    access: proxy
    url: http://tempo.service.consul:3400
    uid: tempo
  - name: Loki
    type: loki
    access: proxy
    url: http://loki.service.consul:3100
    jsonData:
      derivedFields:
        - datasourceUid: tempo
          matcherRegex: (?:traceID|trace_id)=(\w+)
          name: TraceID
          url: $$${__value.raw}
EOTC
        destination = "/local/grafana/provisioning/datasources/ds.yaml"
      }
      artifact {
        source      = "https://raw.githubusercontent.com/cyriltovena/observability-nomad/main/provisioning/dashboard.yaml"
        mode        = "file"
        destination = "/local/grafana/provisioning/dashboards/dashboard.yaml"
      }
      artifact {
        source      = "https://raw.githubusercontent.com/cyriltovena/observability-nomad/main/provisioning/dashboard.json"
        mode        = "file"
        destination = "/local/grafana/dashboards/tns.json"
      }

      resources {
        cpu    = 100
        memory = 512
      }
      service {
        name = "grafana"
        port = "http"

        tags = [
          "monitoring",
          "prometheus",
        ]
        check {
          name     = "Grafana HTTP"
          type     = "http"
          path     = "/api/health"
          interval = "5s"
          timeout  = "2s"

          check_restart {
            limit           = 2
            grace           = "60s"
            ignore_warnings = false
          }
        }
      }
    }
  }
}
