# Terraform Output Without Color (`-no-color`)

This example demonstrates how to use the `-no-color` option to remove ANSI color
escape sequences from Terraform command output.

The scenario: a plan is saved to a text file. With color enabled, the file is
full of terminal escape codes; with `-no-color`, it is plain, readable text.

## Files

| File           | Purpose                                                    |
| -------------- | ---------------------------------------------------------- |
| `main.tf`      | Defines a single AWS security group.                       |
| `color.plan`   | Sample plan output saved **with** ANSI color codes.        |
| `nocolor.plan` | Sample plan output saved with `-no-color`.                 |

## The Configuration

```hcl
resource "aws_security_group" "test_sg" {
  name = "test-sg-01"
}
```

Terraform normally uses color and bold text so additions, changes, and deletions
are easy to spot in a terminal. When that output is redirected to a file, the
formatting is stored as escape sequences such as `\x1b[31m`, which make the file
hard to read and process.

## Prerequisites

- Terraform installed
- AWS credentials configured (e.g. via `AWS_PROFILE`, environment variables, or
  `~/.aws/credentials`)

## Step-by-Step Process

### 1. Initialize the working directory

```bash
terraform init
```

### 2. Save a colored plan

```bash
terraform plan > color.plan
```

### 3. Save a plan without color

```bash
terraform plan -no-color > nocolor.plan
```

The option also works for output shown directly in the terminal:

```bash
terraform plan -no-color
```

### 4. Compare the output

```bash
diff -u color.plan nocolor.plan
```

The plan content is the same, but only `color.plan` includes formatting codes.
To check for the escape character directly:

```bash
grep -c $'\033' color.plan
grep -c $'\033' nocolor.plan
```

The first command reports matching lines; the second reports `0`.

## Key Takeaways

- `-no-color` changes presentation only; it does not change the planned actions.
- Use it when saving output to files, publishing CI/CD logs, or piping output
  into other tools.
- `-no-color` is different from `-out`: use `-out` to save a binary plan for a
  later `terraform apply`.
