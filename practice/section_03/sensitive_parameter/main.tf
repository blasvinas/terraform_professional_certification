resource "local_file" "file" {
  filename = "demo.txt"
  content  = var.password
}

output "file_content" {
  value     = local_file.file.content
  sensitive = true
}

resource "local_sensitive_file" "file" {
  filename = "secret_file.txt"
  content  = "Passw0rd!!"
}

output "sensitive_file_content" {
  value     = local_sensitive_file.file.content
  sensitive = true
}
