# Targeting Specific Resources with `--target`

This example demonstrates how to use the `--target` (or `-target`) option to
limit a Terraform operation to a **subset** of resources instead of the whole
configuration.

The scenario: the configuration defines two AWS security groups (`sg01` and
`sg02`), but we only want to plan/apply changes for `sg02`.

## Files

| File           | Purpose                                                             |
| -------------- | ------------------------------------------------------------------- |
| `versions.tf`  | Pins the Terraform AWS provider (`hashicorp/aws` `6.64.0`).         |
| `providers.tf` | Configures the AWS provider to use the `us-east-1` region.          |
| `main.tf`      | Defines two security groups, `sg01` and `sg02`.                     |

## The Resources

```hcl
resource "aws_security_group" "sg01" {
  name = "sg01"
}

resource "aws_security_group" "sg02" {
  name = "sg02"
}
```

## The `--target` Option

```bash
terraform plan --target "aws_security_group.sg02"
```

- **`--target`** accepts a resource address and restricts the plan (or apply) to
  that resource and its dependencies.
- Only `aws_security_group.sg02` is included in the plan; `sg01` is ignored for
  this operation.
- The option can be repeated to target multiple resources, e.g.
  `--target "aws_security_group.sg01" --target "aws_security_group.sg02"`.

> Terraform prints a warning when `-target` is used, reminding you that the
> resulting plan is a partial view and is intended for exceptional situations
> (such as recovering from errors), not routine use.

## Prerequisites

- Terraform >= 1.0
- AWS credentials configured (e.g. via `AWS_PROFILE`, environment variables, or
  `~/.aws/credentials`)

## Step-by-Step Process

### 1. Initialize the working directory

```bash
terraform init
```

### 2. Plan targeting a single resource

```bash
terraform plan --target "aws_security_group.sg02"
```

The plan output shows only `aws_security_group.sg02` being created, along with a
warning that resource targeting is in effect.

### 3. Apply the targeted change (optional)

```bash
terraform apply --target "aws_security_group.sg02"
```

Only `sg02` is provisioned; `sg01` remains unmanaged/uncreated until a normal
(untargeted) run is performed.

### 4. Apply the full configuration

```bash
terraform apply
```

Without `--target`, Terraform reconciles **all** resources, creating `sg01` as
well.

## Key Takeaways

- `--target` narrows an operation to specific resource addresses and their
  dependencies.
- It is meant for exceptional cases (debugging, recovering from partial
  failures), not everyday workflows.
- Terraform warns you when targeting is active because the plan is only a
  partial representation of the configuration.
- Repeat the flag to target multiple resources in a single command.
