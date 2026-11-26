resource "aws_instance" "servers" {
  count         = 3
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "server${count.index + 1}"
  }
}
