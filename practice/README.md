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

Add each new project README to this table as practice examples are created.
