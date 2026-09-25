resource "local_file" "file" {
  content = "The name of my best friends are \"Alice\" and \"Bob\""
  filename = "test.txt"
}

