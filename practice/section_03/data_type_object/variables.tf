variable "server" {
  type = object({
    name = string
    env  = string
  })
  description = "Server info"
}
