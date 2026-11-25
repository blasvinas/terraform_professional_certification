output "servers" {
  value = var.servers
}

# Display inner values
output "owner" {
  value = var.servers[1]["tags"]["owner"]
}
