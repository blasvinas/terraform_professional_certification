variable "servers" {
  type = list(object({
    name = string
    ips  = list(string)
    tags = map(string)
  }))
  description = "List of servers, each with a name, IP addresses and tags"
}
