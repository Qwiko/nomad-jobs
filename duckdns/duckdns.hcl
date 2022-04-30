job "duckdns" {
  datacenters = ["dc1"]
  
  group "duckdns" {
    count = 1
    
    task "duckdns" {
      env {
        SUBDOMAINS=""
        TOKEN=""
        LOG_FILE=false
        TZ="Europe/Stockholm"
      }
      driver = "docker"
      // resources {
      //   cpu    = 100
      //   memory = 512
      // }
      config {
        image = "lscr.io/linuxserver/duckdns"
      }
    }
  }
}