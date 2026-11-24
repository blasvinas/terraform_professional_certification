resource "aws_instance" "server01" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "server01"
  }

  lifecycle {
    ignore_changes = ["tags"]
  }
}
