variable "servers" {
  type = map(object({
    ami_id        = string,
    instance_type = string
  }))
}
