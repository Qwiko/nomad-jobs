job "heimdall" {
  datacenters = ["dc1"]
  
  group "heimdall" {
    count = 1
    update {
      max_parallel = 1
    }
    network {
      port "http" {
        to = 80
      }
    }
    volume "heimdall" {
      type      = "host"
      read_only = false
      source    = "heimdall"
    }
    service {
        name = "heimdall"
        port = "http"
        tags = ["urlprefix-/"]
        check {
            name     = "Heimdall HTTP"
            type     = "http"
            path     = "/"
            interval = "10s"
            timeout  = "2s"
        }
    }
    task "heimdall" {
      env {
        PUID=1000
        PGID=1000
        TZ="Europe/Stockholm"
      }
      driver = "docker"

      volume_mount {
        volume      = "heimdall"
        destination = "/config"
        read_only   = false
      }

      config {
        image = "lscr.io/linuxserver/heimdall"
        ports = ["http"]
      }
    }
  }
}