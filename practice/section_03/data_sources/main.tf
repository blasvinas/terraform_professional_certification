data "aws_ami" "rhel10" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["RHEL-10.2.0_HVM-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "rhel10" {
  ami           = data.aws_ami.rhel10.image_id
  instance_type = "t3.micro"

  lifecycle {
    ignore_changes = [ami]
  }
}


