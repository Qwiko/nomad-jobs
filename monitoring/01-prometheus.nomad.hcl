job "prometheus" {
  datacenters = ["dc1"]
  type        = "service"

  group "prometheus" {
    count = 1

    network {
      dns {
        servers = ["192.168.10.20"]
      }
      port "http" {
        static = 9090
      }
    }

    restart {
      attempts = 3
      delay    = "20s"
      mode     = "delay"
    }

    task "prometheus" {
      driver = "docker"

      template {
        data        = <<EOTC
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: rabbitmq
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_http" }}:8500'
      services: ['rabbitmq']
    relabel_configs:
    - source_labels: ['__meta_consul_address']
      target_label:  '__address__'
      replacement:   '$1:15692'
  - job_name: traefik
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_http" }}:8500'
      services: ['traefik']
  - job_name: 'nomad_metrics'
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_http" }}:8500'
      services: ['nomad-client', 'nomad']
    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep
    scrape_interval: 5s
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']

  - job_name: 'self'
    consul_sd_configs:
      - server: '172.17.0.1:8500'
    relabel_configs:
      - source_labels: [__meta_consul_service_metadata_external_source]
        target_label: source
        regex: (.*)
        replacement: '$1'
      - source_labels: [__meta_consul_service_id]
        regex: '_nomad-task-([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})-.*'
        target_label:  'task_id'
        replacement: '$1'
      - source_labels: [__meta_consul_tags]
        regex: '.*,prometheus,.*'
        action: keep
      - source_labels: [__meta_consul_tags]
        regex: ',(app|monitoring),'
        target_label:  'group'
        replacement:   '$1'
      - source_labels: [__meta_consul_service]
        target_label: job
      - source_labels: ['__meta_consul_node']
        regex:         '(.*)'
        target_label:  'instance'
        replacement:   '$1'
      
EOTC
        destination = "/local/prometheus.yml"
      }
      config {
        image = "prom/prometheus"
        ports = ["http"]
        args = [
          "--config.file=/local/prometheus.yml",
          "--web.enable-admin-api"
        ]
      }

      resources {
        cpu    = 200
        memory = 200
      }

      service {
        name = "prometheus"
        port = "http"
        tags = ["monitoring","prometheus"]

        check {
          name     = "Prometheus HTTP"
          type     = "http"
          path     = "/targets"
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
