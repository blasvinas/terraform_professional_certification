# Terraform Plan Without Color

This example demonstrates how to use Terraform's `-no-color` option to remove ANSI color escape sequences from command output.

## Configuration

`main.tf` defines an AWS security group:

```hcl
resource "aws_security_group" "test_sg" {
  name = "test-sg-01"
}
```

The existing state causes Terraform to plan a replacement when the configuration is evaluated.

## Generate a Colored Plan

Run a normal plan and redirect the output to a file:

```shell
terraform plan > color.plan
```

When output is intended for an interactive terminal, Terraform uses color and formatting to make additions, changes, and deletions easier to identify. The redirected `color.plan` file can therefore contain ANSI escape sequences such as `\x1b[31m`.

## Generate a Plan Without Color

Use the `-no-color` option to disable color codes:

```shell
terraform plan -no-color > nocolor.plan
```

The resulting `nocolor.plan` file contains readable plain text. This is useful when saving plans to files, publishing logs in CI/CD systems, or processing command output with other tools.

The option can also be used with `plan` output shown directly in the terminal:

```shell
terraform plan -no-color
```

## Compare the Output

Compare the two generated files:

```shell
diff -u color.plan nocolor.plan
```

The plan content is the same, but `color.plan` includes terminal formatting sequences and `nocolor.plan` does not. To check for ANSI escape characters directly:

```shell
grep -n $'\\033' color.plan
! grep -n $'\\033' nocolor.plan
```

The first command should find matches in the colored output. The `!` before the second command makes the check succeed when no escape characters are found in the plain-text output.

## Notes

- `-no-color` changes presentation only; it does not change the planned infrastructure actions.
- The `-no-color` option is different from `-out`. Use `-out` when you need to save a binary plan for a later `terraform apply`.
- Run `terraform init` before the first plan if the provider has not been initialized in this directory.
