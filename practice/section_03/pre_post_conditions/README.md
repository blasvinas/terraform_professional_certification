# Preconditions and Postconditions in Terraform

This example demonstrates how to use
[custom conditions](https://developer.hashicorp.com/terraform/language/expressions/custom-conditions)
(`precondition` and `postcondition` blocks) inside a resource's `lifecycle`
block to check assumptions **before** and **after** Terraform works on a
resource.

The scenario: an EC2 instance must be a `t3.micro` and must be created in the
`us-east-1` region. A precondition checks the instance type, and a
postcondition checks the region of the instance.

## Files

| File                  | Purpose                                                           |
| --------------------- | ----------------------------------------------------------------- |
| `versions.tf`         | Pins the AWS provider (`hashicorp/aws` `6.73.0`).                 |
| `providers.tf`        | Configures the AWS provider for the `us-east-1` region.           |
| `variables.tf`        | Declares the `instance_type` and `ami_id` input variables.        |
| `terraform.tfvars`    | Sets the variable values (`t3.micro` and an AMI ID).              |
| `main.tf`             | Defines the `aws_instance` with a precondition and a postcondition. |
| `.terraform.lock.hcl` | Dependency lock file created by `terraform init`.                 |

## The Configuration

### `main.tf`

```hcl
resource "aws_instance" "server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  lifecycle {
    precondition {
      condition     = var.instance_type == "t3.micro"
      error_message = "The instance must be of type t3.micro"
    }

    postcondition {
      condition     = self.region == "us-east-1"
      error_message = "Instance must be created in the us-east-1 region"
    }
  }
}
```

### `precondition`: check the inputs

- Checked **before** Terraform plans the change to the resource.
- Used to check **assumptions**: values the resource depends on, such as
  variables, data sources, or other resources.
- Here it makes sure `var.instance_type` is `t3.micro`. If not, planning stops
  and nothing is created.

### `postcondition`: check the result

- Checked **after** Terraform plans or applies the change to the resource.
- Used to check **guarantees**: that the resulting object looks as expected.
- It can use `self` to refer to the resource's own attributes. `self` is only
  allowed in postconditions.
- Here it makes sure `self.region` is `us-east-1`. With AWS provider v6, every
  resource has a `region` attribute. It comes from the provider configuration
  unless it is set on the resource.
- If the attribute is already known at plan time (as `region` is here), the
  postcondition fails during `plan`. If it is only `(known after apply)`, it is
  checked during `apply`, **after** the resource has been created or changed.

### `variables.tf` and `terraform.tfvars`

```hcl
variable "instance_type" {
  type        = string
  description = "instance_type"
}

variable "ami_id" {
  type        = string
  description = "AMI ID"
}
```

```hcl
ami_id        = "ami-0aacbf72109c53c0c"
instance_type = "t3.micro"
```

Terraform loads `terraform.tfvars` automatically, so no `-var` options are
needed.

## Preconditions vs. Postconditions vs. Variable Validation

|                    | `validation` (in `variable`)   | `precondition`                       | `postcondition`                      |
| ------------------ | ------------------------------ | ------------------------------------ | ------------------------------------ |
| Where              | `variable` block               | `lifecycle` of a resource or data source, or an `output` | `lifecycle` of a resource or data source |
| When it runs       | When the value is set          | Before the resource is planned       | After the resource is planned or applied |
| Can reference      | The variable (and, since 1.9, other objects) | Variables, data sources, other resources | Same, plus `self`             |
| Typical purpose    | Reject bad input               | Check assumptions                    | Check guarantees about the result    |

## Prerequisites

- Terraform installed
- An AWS account with credentials configured (for example `aws configure`, or
  the `AWS_PROFILE` / `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` environment
  variables)
- A default VPC in `us-east-1` (no subnet is set, so AWS uses the default VPC)
- The AMI in `terraform.tfvars` must exist in `us-east-1`

> **Cost:** `terraform apply` launches a real EC2 instance. Destroy it when you
> are done. The `plan` steps below do not create anything.

## Step-by-Step Process

### 1. Initialize the working directory

```bash
terraform init
```

### 2. Plan with valid values

```bash
terraform plan
```

Both conditions pass:

```text
      + ami           = "ami-0aacbf72109c53c0c"
      + instance_type = "t3.micro"
      + region        = "us-east-1"
...
Plan: 1 to add, 0 to change, 0 to destroy.
```

### 3. Make the precondition fail

```bash
terraform plan -var instance_type=t2.micro
```

The `-var` option overrides the value from `terraform.tfvars`:

```text
Error: Resource precondition failed

  on main.tf line 7, in resource "aws_instance" "server":
   7:       condition     = var.instance_type == "t3.micro"
    ├────────────────
    │ var.instance_type is "t2.micro"

The instance must be of type t3.micro
```

### 4. Make the postcondition fail

Temporarily change the region in `providers.tf` (for example to `eu-west-1`)
and run:

```bash
terraform plan
```

Because the region is known at plan time, the postcondition fails before
anything is created:

```text
Error: Resource postcondition failed

  on main.tf line 12, in resource "aws_instance" "server":
  12:       condition     = self.region == "us-east-1"
    ├────────────────
    │ self.region is "eu-west-1"

Instance must be created in the us-east-1 region
```

Change the region back to `us-east-1` afterwards.

### 5. Apply and clean up (optional)

```bash
terraform apply
terraform destroy
```

## Notes

- **A failed postcondition during `apply` does not undo the change.** The
  resource is already created or updated in AWS and is saved in the state.
  Terraform only reports the error and stops before working on resources that
  depend on it.
- **This precondition could also be a variable validation.** It only checks
  `var.instance_type`, so a `validation` block in the variable would work too.
  Preconditions are most useful when the check uses other objects, such as a
  data source (for example, checking that an AMI's architecture matches the
  instance type).

## Key Takeaways

- `precondition` and `postcondition` blocks go inside a resource's `lifecycle`
  block. Each has a `condition` and an `error_message`.
- Preconditions check **assumptions** before the resource is planned.
- Postconditions check **guarantees** about the result, and can use `self`.
- A postcondition is checked during `plan` if the values are known, otherwise
  during `apply`.
- A failing condition stops Terraform with a clear error message, so problems
  are found early instead of in production.
