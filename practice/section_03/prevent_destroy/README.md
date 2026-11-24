# Protecting Resources with `lifecycle { prevent_destroy }`

This example demonstrates how to use the
[`prevent_destroy`](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#prevent_destroy)
lifecycle argument to stop Terraform from **destroying** an important
resource by accident.

The scenario: an EC2 instance must not be deleted. With
`prevent_destroy = true`, any plan that would destroy it (a `terraform destroy`
or a change that forces a replacement) fails with an error, and nothing is
changed.

## Files

| File                  | Purpose                                                          |
| --------------------- | ---------------------------------------------------------------- |
| `versions.tf`         | Pins the AWS provider (`hashicorp/aws` `6.74.0`).                |
| `providers.tf`        | Configures the AWS provider for the `us-east-1` region.          |
| `variables.tf`        | Declares the `ami_id` and `instance_type` input variables.       |
| `terraform.tfvars`    | Sets the variable values (an AMI ID and `t3.micro`).             |
| `main.tf`             | Defines the `aws_instance` with `prevent_destroy = true`.        |
| `.terraform.lock.hcl` | Dependency lock file created by `terraform init`.                |
| `terraform.tfstate`   | State of the instance created in this exercise.                  |

## The Configuration

### `main.tf`

```hcl
resource "aws_instance" "server01" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "server01"
  }

  lifecycle {
    prevent_destroy = true
  }
}
```

- **`lifecycle`**: a meta-argument block that changes how Terraform handles a
  resource. It works with every resource type.
- **`prevent_destroy = true`**: Terraform rejects any plan that would destroy
  this resource.
- The check happens during **`plan`**, so nothing is changed in AWS when it
  fails.

### `variables.tf` and `terraform.tfvars`

```hcl
variable "ami_id" {
  type        = string
  description = "Image ID"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
}
```

```hcl
ami_id        = "ami-0aacbf72109c53c0c"
instance_type = "t3.micro"
```

Terraform loads `terraform.tfvars` automatically.

## What `prevent_destroy` Blocks

| Action                                         | Result with `prevent_destroy = true` |
| ---------------------------------------------- | ------------------------------------ |
| Create the resource                            | Allowed                              |
| Update in place (for example, change a tag)    | Allowed                              |
| `terraform destroy` / `terraform plan -destroy` | **Error**                            |
| Change that forces replacement (for example, a new AMI) | **Error**                   |
| `terraform apply -replace=aws_instance.server01` | **Error**                          |
| Remove the `resource` block from the code      | Allowed: the resource **is destroyed** |
| Delete it outside Terraform (AWS Console, CLI) | Not prevented                        |

## Prerequisites

- Terraform installed
- An AWS account with credentials configured (for example `aws configure`, or
  the `AWS_PROFILE` / `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` environment
  variables)
- A default VPC in `us-east-1` (no subnet is set, so AWS uses the default VPC)

> **Cost:** this example launches a real EC2 instance. Because it is protected,
> you must remove the protection before you can destroy it (see
> [step 6](#6-clean-up)).

## Step-by-Step Process

### 1. Initialize and create the instance

```bash
terraform init
terraform apply
```

Creating the instance is not affected by `prevent_destroy`.

### 2. Try to destroy it

```bash
terraform destroy
```

Terraform plans the destroy, then stops with an error (exit code `1`):

```text
Plan: 0 to add, 0 to change, 1 to destroy.

Error: Instance cannot be destroyed

  on main.tf line 1:
   1: resource "aws_instance" "server01" {

Resource aws_instance.server01 has lifecycle.prevent_destroy set, but the
plan calls for this resource to be destroyed. To avoid this error and
continue with the plan, either disable lifecycle.prevent_destroy or reduce
the scope of the plan using the -target option.
```

### 3. Try a change that forces a replacement

A new AMI requires a new instance, which means destroying the old one:

```bash
terraform plan -var ami_id=ami-062caee4b7b602eb0
```

```text
  # aws_instance.server01 must be replaced
-/+ resource "aws_instance" "server01" {

Plan: 1 to add, 0 to change, 1 to destroy.

Error: Instance cannot be destroyed
```

### 4. Make an in-place change

Change the tag in `main.tf` (for example `Name = "web01"`) and run
`terraform plan`. This is allowed, because nothing is destroyed:

```text
  ~ update in-place

Plan: 0 to add, 1 to change, 0 to destroy.
```

Change the tag back afterwards.

### 5. Removing the resource block is NOT prevented

If the whole `resource` block is deleted from `main.tf`, the `prevent_destroy`
setting is deleted with it. Terraform then plans to destroy the instance
without any error:

```text
  # aws_instance.server01 will be destroyed
  # (because aws_instance.server01 is not in configuration)

Plan: 0 to add, 0 to change, 1 to destroy.
```

To stop managing a resource **without** destroying it, use a
[`removed` block](https://developer.hashicorp.com/terraform/language/resources/syntax#removing-resources)
instead (Terraform 1.7 or later):

```hcl
removed {
  from = aws_instance.server01

  lifecycle {
    destroy = false
  }
}
```

### 6. Clean up

To destroy the instance, first set `prevent_destroy = false` (or remove the
`lifecycle` block), then run:

```bash
terraform destroy
```

## Notes

- **The instance is still running.** The state shows the instance
  `i-012d242ac7d4e309d` as `running`. Follow [step 6](#6-clean-up) when you no
  longer need it, to avoid charges.
- **It only protects against Terraform.** The instance can still be deleted in
  the AWS Console or with the AWS CLI. For that, use AWS features such as
  `disable_api_termination = true` (EC2 termination protection) or
  `deletion_protection` on databases and load balancers.
- **It can make normal changes harder.** Every change that forces a replacement
  is blocked too. Use `prevent_destroy` only for resources that are costly or
  dangerous to lose, such as databases, S3 buckets with data, or KMS keys.
- **The value must be a literal.** `prevent_destroy` cannot use variables or
  other expressions; it must be written as `true` or `false`.

## Key Takeaways

- `prevent_destroy = true` makes any plan that would destroy the resource fail
  with an error.
- It blocks `terraform destroy` and changes that force replacement, but allows
  creation and in-place updates.
- Deleting the resource block also deletes the protection. Use a `removed`
  block with `destroy = false` to stop managing a resource safely.
- It does not protect against changes made outside Terraform; combine it with
  cloud-side protection when needed.
- To destroy a protected resource on purpose, set `prevent_destroy = false`
  first.
