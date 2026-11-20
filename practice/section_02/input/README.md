# Required Input Variables and `-input=false`

This example demonstrates how Terraform fails when a required input variable is
not provided, and how the `-input=false` option makes that failure immediate
instead of prompting for a value.

The scenario: a `local_file` resource takes its filename from a variable that
has no default value, so Terraform cannot plan until the value is supplied.

## Files

| File      | Purpose                                                                |
| --------- | ---------------------------------------------------------------------- |
| `main.tf` | Declares the required `file_name` variable and a `local_file` resource. |

## The Configuration

```hcl
variable "file_name" {}

resource "local_file" "foo" {
  content  = "Hello, World!"
  filename = var.file_name
}
```

- **`file_name`** — declared without a `default`, so the root module requires
  a value before Terraform can plan or apply.
- **`local_file.foo`** — writes `Hello, World!` to the file named by
  `var.file_name`.

By default, Terraform prompts interactively for missing variables. With
`-input=false`, it fails instead, which is the behaviour you want in automation
and CI/CD pipelines where nobody can answer a prompt.

## Prerequisites

- Terraform installed
- Network access to the Terraform Registry (for `terraform init`)

No cloud credentials are required. The `local` provider only writes files on the
machine running Terraform.

## Step-by-Step Process

### 1. Initialize the working directory

```bash
terraform init
```

### 2. Reproduce the failure

```bash
terraform plan -input=false
```

Terraform fails with an error similar to:

```text
Error: No value for required variable

The root module input variable "file_name" is not set, and has no default value.
Use a -var or -var-file command line argument to provide a value.
```

### 3. Provide the value on the command line

```bash
terraform plan -input=false -var='file_name=hello.txt'
terraform apply -input=false -auto-approve -var='file_name=hello.txt'
```

The apply creates `hello.txt` containing:

```text
Hello, World!
```

### 4. Provide the value with a variable definitions file (optional)

Create `terraform.tfvars`:

```hcl
file_name = "hello.txt"
```

Terraform loads `terraform.tfvars` automatically, so no `-var` is needed:

```bash
terraform plan -input=false
terraform apply -input=false -auto-approve
```

### 5. Clean up

```bash
terraform destroy -input=false -auto-approve -var='file_name=hello.txt'
```

## Key Takeaways

- A variable without a `default` is required; Terraform cannot plan without it.
- Without `-input=false`, Terraform prompts for missing values interactively.
- `-input=false` turns the prompt into an immediate error, which is safer for
  automation.
- Supply values with `-var`, `-var-file`, `terraform.tfvars`, or `TF_VAR_*`
  environment variables.
