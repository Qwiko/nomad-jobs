job "registry" {
  datacenters = ["dc1"]
  
  group "registry" {
    count = 1
    network {
      port "docker" {
        static = 5000
      }
    }
	    
    task "registry" {
      env {
        TZ="Europe/Stockholm"
      }
      driver = "docker"
	  service {
		name = "registry"
		port = "docker"
		tags = ["registry"]
	  }

      config {
        image = "registry:2"
        ports = ["docker"]
		volumes = [
          "/home/nomad/registry:/var/lib/registry"
        ]
      }
    }
  }
}

