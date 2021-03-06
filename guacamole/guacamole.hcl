job "guacamole" {
  datacenters = ["dc1"]
  
  group "guacamole" {
    count = 1
    update {
      max_parallel = 1
    }
    network {
      port "http" {
        to = 8080
      }
    }
    service {
        name = "guacamole"
        port = "http"
        tags = ["urlprefix-/"]
        check {
            name     = "Guacamole HTTP"
            type     = "http"
            path     = "/"
            interval = "10s"
            timeout  = "2s"
        }
    }
    task "guacamole" {
      env {
        #PUID=1000
        #PGID=1000
        TZ="Europe/Stockholm"
      }
      driver = "docker"
      resources {
        cpu    = 100
        memory = 512
      }
      config {
        image = "oznu/guacamole"
        ports = ["http"]
        volumes = [
          "/home/nomad/guacamole:/config"
        ]
      }
    }
  }
}