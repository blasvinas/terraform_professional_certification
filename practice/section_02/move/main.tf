resource "aws_security_group" "sg02" {
  name = "test_sg"
}

moved {
  from = aws_security_group.sg01
  to   = aws_security_group.sg02
}
