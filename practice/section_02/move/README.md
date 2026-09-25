# Refactoring Resources with the `moved` Block

This example demonstrates how to use the [`moved` block](https://developer.hashicorp.com/terraform/language/moved)
to rename a resource **without destroying and recreating it**.

The scenario: a security group was originally defined as
`aws_security_group.sg01`. We rename it to `aws_security_group.sg02` and use a
`moved` block to tell Terraform that the existing state object should be moved
to the new address rather than being replaced.

## Files

| File           | Purpose                                                             |
| -------------- | ------------------------------------------------------------------- |
| `versions.tf`  | Pins the Terraform AWS provider (`hashicorp/aws` `6.64.0`).         |
| `providers.tf` | Configures the AWS provider to use the `us-east-1` region.          |
| `main.tf`      | Defines the renamed security group and the `moved` block.           |

## The `moved` Block

```hcl
resource "aws_security_group" "sg02" {
  name = "test_sg"
}

moved {
  from = aws_security_group.sg01
  to   = aws_security_group.sg02
}
```

- **`from`** — the old resource address (`aws_security_group.sg01`).
- **`to`** — the new resource address (`aws_security_group.sg02`).

When Terraform plans, it sees the existing object in state at the `from` address
and updates the state to the `to` address. No destroy/create happens, so the
underlying AWS security group is preserved.

## Why Not Just Rename?

If you rename a resource in your configuration **without** a `moved` block,
Terraform has no way to know the two addresses refer to the same object. It
would plan to **destroy** `sg01` and **create** `sg02`, which can cause downtime
and data loss. The `moved` block makes the refactor safe and non-destructive.

## Prerequisites

- Terraform >= 1.1 (when `moved` blocks were introduced)
- AWS credentials configured (e.g. via `AWS_PROFILE`, environment variables, or
  `~/.aws/credentials`)
- Existing state containing `aws_security_group.sg01`

## Step-by-Step Process

### 1. Start with the original resource

```hcl
resource "aws_security_group" "sg01" {
  name = "test_sg"
}
```

Apply it so it exists in state:

```bash
terraform init
terraform apply
```

### 2. Rename the resource and add the `moved` block

Change the resource label from `sg01` to `sg02` and declare the move (as shown
in `main.tf`).

### 3. Plan to confirm the move

```bash
terraform plan
```

The plan output reports that the resource will be **moved** (e.g.
`aws_security_group.sg01` has moved to `aws_security_group.sg02`) with no
destructive actions.

### 4. Apply the refactor

```bash
terraform apply
```

Terraform updates the state address only; the real security group is untouched.

### 5. Verify

```bash
terraform state list
```

You should see `aws_security_group.sg02` and no longer `aws_security_group.sg01`.

### 6. Clean up (optional)

Once the move has been applied and the new address is in state, the `moved`
block can be safely removed. It is only needed to guide the transition.

## Key Takeaways

- The `moved` block lets you rename or refactor resources without recreating
  them.
- Without it, renaming a resource triggers a destroy/create cycle.
- `from` and `to` are Terraform resource addresses, not provider IDs.
- `moved` blocks are safe to remove after a successful apply.
