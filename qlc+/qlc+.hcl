job "qlc" {
  datacenters = ["dc1"]
  
  group "qlc" {
    count = 1
    update {
      max_parallel = 1
    }
    network {
      port "http" {
        to = 9999
      }
    }
    service {
        name = "qlc"
        port = "http"
        tags = ["urlprefix-/"]
        check {
            name     = "QLC HTTP"
            type     = "http"
            path     = "/"
            interval = "10s"
            timeout  = "2s"
        }
    }
    task "qlc" {
      env {
        TZ="Europe/Stockholm"
      }
      driver = "docker"

      config {
        image = "binary1230/qlcplus"
        ports = ["http"]
      }
    }
  }
}