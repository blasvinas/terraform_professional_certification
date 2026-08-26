variable "file_name" {}

resource "local_file" "foo" {
  content  = "Hello, World!"
  filename = var.file_name
}
