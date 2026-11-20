# Running Terraform in Automation with `TF_IN_AUTOMATION`

This example demonstrates the effect of the `TF_IN_AUTOMATION` environment
variable on Terraform's command output.

The scenario: Terraform runs inside a CI/CD pipeline, where hints such as "run
`terraform apply` next" are not useful because the next step is already
scripted.

## Files

| File      | Purpose                                     |
| --------- | ------------------------------------------- |
| `main.tf` | Defines a single AWS security group.        |

## The Configuration

```hcl
resource "aws_security_group" "sg" {
  name = "test-sg"
}
```

## What Is `TF_IN_AUTOMATION`?

When `TF_IN_AUTOMATION` is set to **any non-empty value**, Terraform assumes it
is running in an automated pipeline rather than an interactive terminal.

- It **suppresses hints** that suggest follow-up CLI commands. For example, after
  `terraform plan` Terraform normally suggests running `terraform apply`; with
  the variable set, that suggestion is omitted.
- It does **not** change the behaviour of plan, apply, or destroy, and it does
  **not** disable interactive prompts. Use `-input=false` and `-auto-approve`
  for that.

The value itself is irrelevant; common conventions are `TF_IN_AUTOMATION=true`
or `TF_IN_AUTOMATION=1`.

## Prerequisites

- Terraform installed
- AWS credentials configured (e.g. via `AWS_PROFILE`, environment variables, or
  `~/.aws/credentials`)

## Step-by-Step Process

### 1. Initialize the working directory

```bash
terraform init
```

### 2. Plan without the variable

```bash
unset TF_IN_AUTOMATION
terraform plan
```

Note the hint at the end of the output suggesting the next command to run.

### 3. Plan with the variable

```bash
TF_IN_AUTOMATION=true terraform plan
```

The follow-up command hints are gone.

### 4. Use it in a non-interactive pipeline (optional)

```bash
export TF_IN_AUTOMATION=true

terraform init -input=false
terraform plan -input=false -out=tfplan
terraform apply -input=false tfplan
```

## Key Takeaways

- `TF_IN_AUTOMATION` only adjusts output to suit automation; it is purely
  cosmetic.
- Terraform only checks whether the variable is set and non-empty.
- Combine it with `-input=false` and `-auto-approve` (or a saved plan) for a
  fully non-interactive pipeline.

## References

- [Running Terraform in Automation](https://developer.hashicorp.com/terraform/tutorials/automation/automate-terraform)
