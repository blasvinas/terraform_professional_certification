# Terraform Practice

Index of the practice projects and their documentation.

## Projects

| Section | Project | Description | Documentation |
| --- | --- | --- | --- |
| Section 02 | `input` | Demonstrates how Terraform fails when a required input variable is not provided. | [README.md](section_02/input/README.md) |
| Section 02 | `nocolor` | Demonstrates how to remove ANSI color codes from Terraform command output. | [README.md](section_02/nocolor/README.md) |
| Section 02 | `plugin_caching` | Demonstrates how Terraform reuses provider packages from a local plugin cache. | [README.md](section_02/plugin_caching/README.md) |
| Section 02 | `mirror` | Demonstrates how to create and use a local filesystem mirror for Terraform providers. | [README.md](section_02/mirror/README.md) |
| Section 02 | `tf_automation` | Demonstrates the effect of the `TF_IN_AUTOMATION` environment variable when running Terraform. | [README.md](section_02/tf_automation/README.md) |
| Section 02 | `import` | Demonstrates how to import an existing AWS resource using the `import` block. | [README.md](section_02/import/README.md) |
| Section 02 | `target` | Demonstrates how to limit a Terraform operation to specific resources using `--target`. | [README.md](section_02/target/README.md) |
| Section 02 | `move` | Demonstrates how to rename a resource without recreating it using the `moved` block. | [README.md](section_02/move/README.md) |
| Section 02 | `random` | Demonstrates how to generate a random integer with the `random` provider and expose it as an output. | [README.md](section_02/random/README.md) |
| Section 03 | `escape_sequences` | Demonstrates how to use string escape sequences in Terraform. | [README.md](section_03/escape_sequences/README.md) |
| Section 03 | `heredoc` | Demonstrates multi-line strings with standard (`<<EOT`) and indented (`<<-EOT`) heredoc syntax. | [README.md](section_03/heredoc/README.md) |
| Section 03 | `jason` | Demonstrates converting between Terraform values and JSON with `jsonencode` and `jsondecode`. | [README.md](section_03/jason/README.md) |
| Section 03 | `data_sources` | Demonstrates using the `aws_ami` data source to look up the latest RHEL 10.2 x86_64 AMI for an EC2 instance, with `ignore_changes` to avoid replacement when new AMIs are published. | [README.md](section_03/data_sources/README.md) |
| Section 03 | `input_variable_validation` | Demonstrates custom `validation` blocks on input variables using `length()`, `contains()`, `can()`/`regex()`, and `substr()`. | [README.md](section_03/input_variable_validation/README.md) |
| Section 03 | `pre_post_conditions` | Demonstrates `precondition` and `postcondition` blocks in a resource `lifecycle` to check an EC2 instance's type and region. | [README.md](section_03/pre_post_conditions/README.md) |
| Section 03 | `check_block` | Demonstrates a `check` block with a scoped `http` data source and an `assert` that warns (without failing) when a website is down. | [README.md](section_03/check_block/README.md) |
| Section 03 | `sensitive_parameter` | Demonstrates hiding secrets with sensitive variables, sensitive outputs, and the `local_sensitive_file` resource. | [README.md](section_03/sensitive_parameter/README.md) |
| Section 03 | `ignore_changes` | Demonstrates `lifecycle { ignore_changes }` to keep tags added outside of Terraform from being removed on an EC2 instance. | [README.md](section_03/ignore_changes/README.md) |
| Section 03 | `create_before_destroy` | Demonstrates `lifecycle { create_before_destroy }` to create a replacement EC2 instance before destroying the old one. | [README.md](section_03/create_before_destroy/README.md) |
| Section 03 | `prevent_destroy` | Demonstrates `lifecycle { prevent_destroy }` to block plans that would destroy or replace an EC2 instance. | [README.md](section_03/prevent_destroy/README.md) |
| Section 03 | `data_type_list` | Demonstrates a `list(string)` input variable set in `terraform.tfvars` and returned as an output. | [README.md](section_03/data_type_list/README.md) |
| Section 03 | `data_type_map` | Demonstrates a `map` input variable set in `terraform.tfvars`, returned as an output, and used with map functions. | [README.md](section_03/data_type_map/README.md) |
| Section 03 | `data_type_object` | Demonstrates an `object` input variable with typed attributes, set in `terraform.tfvars` and returned as an output. | [README.md](section_03/data_type_object/README.md) |
| Section 03 | `nesting_types` | Demonstrates nested types: a `list(object({...}))` variable whose objects contain a string, a list and a map. | [README.md](section_03/nesting_types/README.md) |

Add each new project README to this table as practice examples are created.
