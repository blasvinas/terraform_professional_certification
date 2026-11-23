resource "aws_instance" "server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  lifecycle {
    precondition {
      condition     = var.instance_type == "t3.micro"
      error_message = "The instance must be of type t3.micro"
    }

    postcondition {
      condition     = self.region == "us-east-1"
      error_message = "Instance must be created in the us-east-1 region"
    }
  }
}
