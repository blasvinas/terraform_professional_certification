resource "aws_instance" "servers" {
  for_each      = var.servers
  ami           = each.value.ami_id
  instance_type = each.value.instance_type

  tags = {
    "Name" = each.key
  }
}
