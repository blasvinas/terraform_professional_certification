output "person_json" {
  description = "The person object encoded as a JSON string"
  value       = local.person_json
}

output "person_back" {
  description = "The JSON string decoded back into an object"
  value       = local.person_back
}

output "person_name" {
  description = "Attribute access on the decoded object"
  value       = local.person_back.Name
}
