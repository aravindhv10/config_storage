# /etc/nomad.d/nomad.hcl

data_dir  = "/opt/nomad/data"
plugin_dir = "/opt/nomad/plugins"
bind_addr = "0.0.0.0" # Listen on all interfaces
datacenter = "single-cp"

# 1. Server Configuration
server {
  enabled          = true
  bootstrap_expect = 3
}

# 2. Client Configuration (to run workloads on these nodes)
client {
  enabled = true
}

# 3. Consul Integration (The "Automatic" part)
consul {
  address = "127.0.0.1:8500" # Your local Consul agent
  
  # Automatically register and find peers
  server_auto_join = true
  client_auto_join = true
  
  # Register the Nomad services in Consul
  auto_advertise = true
  server_service_name = "nomad"
  client_service_name = "nomad-client"
}

plugin "nomad-device-nvidia" {
  config {
    enabled            = true
    ignored_gpu_ids    = ["GPU-fef8089b", "GPU-ac81e44d"]
    fingerprint_period = "1m"
  }
}
