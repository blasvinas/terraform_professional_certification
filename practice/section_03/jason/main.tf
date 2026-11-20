locals {
  person = {
    Name = "Blas"
    Age  = 55
  }

  # Object -> JSON string
  person_json = jsonencode(local.person)

  # JSON string -> object (round trip)
  person_back = jsondecode(local.person_json)
}
