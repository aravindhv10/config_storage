# /etc/consul.d/consul.hcl

node_name  = "#NODE_NAME#" # Change to node-2, node-3 accordingly
data_dir   = "/opt/consul"
datacenter = "single-cp"
server     = true

# The number of servers expected in the cluster
bootstrap_expect = 3

# Internal IP of this specific node
bind_addr = "#NODE_IP#" 

# IPs of the other nodes to join the cluster automatically
retry_join = ["10.10.8.17", "10.10.8.16", "10.10.8.14"]

# Performance & Security (Recommended for Production)
performance {
  raft_multiplier = 1
}

ui_config {
  enabled = true
}
