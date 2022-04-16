job "companion" {
  datacenters = ["dc1"]
  
  group "companion" {
    count = 1
    network {
      port "http" {
        to = 8000
      }
    }
    volume "companion" {
      type      = "host"
      read_only = false
      source    = "companion"
    }
    service {
        name = "companion"
        port = "http"
        tags = ["urlprefix-/"]
        // check {
        //     name     = "companion HTTP"
        //     type     = "http"
        //     path     = "/"
        //     interval = "10s"
        //     timeout  = "2s"
        // }
    }
    task "companion" {
      env {
        // PUID=1000
        // PGID=1000
        COMPANION_CONFIG_BASEDIR="/companion"
        TZ="Europe/Stockholm"
      }
      driver = "docker"

      volume_mount {
        volume      = "companion"
        destination = "/companion"
        read_only   = false
      }

      config {
        image = "ghcr.io/bitfocus/companion/companion"
        ports = ["http"]
      }
    }
  }
}

