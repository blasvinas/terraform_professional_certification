resource "local_file" "file1" {
  filename = "heredoc_spaces.txt"
  content  = <<EOT
    This is line 1 
      This is line 2 
        This is line 3 
  EOT 
}


resource "local_file" "file2" {
  filename = "heredoc_no_spaces.txt"
  content  = <<-EOT
    This is line 1 
      This is line 2 
        This is line 3 
  EOT 
}
