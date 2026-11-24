# Replacing Resources with `lifecycle { create_before_destroy }`

This example demonstrates how to use the
[`create_before_destroy`](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#create_before_destroy)
lifecycle argument to change the order in which Terraform **replaces** a
resource.

Some changes cannot be made in place. For example, changing the AMI of an EC2
instance requires a new instance. By default, Terraform **destroys** the old
instance first and then **creates** the new one, so for a short time there is
no instance at all. With `create_before_destroy = true`, Terraform creates the
new instance first and destroys the old one only after the new one is ready.

## Files

| File                  | Purpose                                                          |
| --------------------- | ---------------------------------------------------------------- |
| `versions.tf`         | Pins the AWS provider (`hashicorp/aws` `6.74.0`).                |
| `providers.tf`        | Configures the AWS provider for the `us-east-1` region.          |
| `variables.tf`        | Declares the `ami_id` and `instance_type` input variables.       |
| `terraform.tfvars`    | Sets the variable values (an AMI ID and `t3.micro`).             |
| `main.tf`             | Defines the `aws_instance` with `create_before_destroy = true`.  |
| `.terraform.lock.hcl` | Dependency lock file created by `terraform init`.                |

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
    create_before_destroy = true
  }
}
```

- **`lifecycle`**: a meta-argument block that changes how Terraform handles a
  resource. It works with every resource type.
- **`create_before_destroy = true`**: when the resource must be replaced,
  create the new object first, then destroy the old one.
- It only matters for **replacements**. Normal in-place updates (for example,
  changing a tag) and plain `terraform destroy` are not affected.

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
ami_id        = "ami-062caee4b7b602eb0"
instance_type = "t3.micro"
```

Terraform loads `terraform.tfvars` automatically. Changing `ami_id` is an easy
way to force a replacement, because a new AMI requires a new instance.

## Default vs. `create_before_destroy`

|                          | Default (`false`)                     | `create_before_destroy = true`         |
| ------------------------ | ------------------------------------- | -------------------------------------- |
| Plan symbol              | `-/+`                                 | `+/-`                                  |
| Plan text                | `destroy and then create replacement` | `create replacement and then destroy`  |
| Order during `apply`     | Destroy old → create new              | Create new → destroy old               |
| Gap with no resource     | Yes                                   | No                                     |
| Both exist at once       | No                                    | Yes, for a short time                  |

While the old object waits to be destroyed, Terraform calls it a
**deposed object**.

## Prerequisites

- Terraform installed
- An AWS account with credentials configured (for example `aws configure`, or
  the `AWS_PROFILE` / `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` environment
  variables)
- A default VPC in `us-east-1` (no subnet is set, so AWS uses the default VPC)
- Two AMI IDs that exist in `us-east-1` (one to create the instance and one to
  replace it)

> **Cost:** this example launches real EC2 instances, and during a replacement
> two instances run at the same time. Destroy everything when you are done.

## Step-by-Step Process

### 1. Initialize and create the instance

```bash
terraform init
terraform apply
```

### 2. Force a replacement

Change `ami_id` to a different AMI, either in `terraform.tfvars` or on the
command line:

```bash
terraform apply -var ami_id=<another-ami-id>
```

The plan shows `+/-` because `create_before_destroy` is enabled:

```text
  # aws_instance.server01 must be replaced
+/- resource "aws_instance" "server01" {
      ~ ami = "<old-ami-id>" -> "<another-ami-id>" # forces replacement
      ...
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

During the apply, the new instance is created **before** the old one (the
deposed object) is destroyed:

```text
aws_instance.server01: Creating...
aws_instance.server01: Creation complete after ... [id=i-<new>]
aws_instance.server01 (deposed object 30b6b48d): Destroying... [id=i-<old>]
aws_instance.server01: Destruction complete after ...
```

### 3. Compare with the default behaviour

Remove the `lifecycle` block (or set `create_before_destroy = false`) and
change the AMI again. The plan now shows `-/+`, and the old instance is
destroyed first:

```text
-/+ resource "aws_instance" "server01" {

aws_instance.server01: Destroying... [id=i-<old>]
aws_instance.server01: Destruction complete after ...
aws_instance.server01: Creating...
aws_instance.server01: Creation complete after ... [id=i-<new>]
```

### 4. Clean up

```bash
terraform destroy
```

## Try It Without AWS

The same ordering can be seen at no cost with the built-in `terraform_data`
resource (no provider or credentials needed). In an empty directory, create
`main.tf`:

```hcl
variable "v" {
  type = string
}

resource "terraform_data" "server01" {
  triggers_replace = var.v

  lifecycle {
    create_before_destroy = true
  }
}
```

```bash
terraform init
terraform apply -auto-approve -var v=a
terraform apply -auto-approve -var v=b
```

Changing `triggers_replace` forces a replacement. With
`create_before_destroy = true` the output is:

```text
+/- create replacement and then destroy
...
terraform_data.server01: Creating...
terraform_data.server01: Creation complete after 0s [id=c529f5af-...]
terraform_data.server01 (deposed object 30b6b48d): Destroying... [id=cbe8dbde-...]
terraform_data.server01: Destruction complete after 0s
```

With `create_before_destroy = false`:

```text
-/+ destroy and then create replacement
...
terraform_data.server01: Destroying... [id=d1587ffc-...]
terraform_data.server01: Destruction complete after 0s
terraform_data.server01: Creating...
terraform_data.server01: Creation complete after 0s [id=e648a4e9-...]
```

## Notes

- **Unique names can cause conflicts.** Because the old and new objects exist
  at the same time, resources whose names must be unique (S3 buckets, IAM
  roles, security groups, load balancers, and so on) fail with an "already
  exists" error. Use `name_prefix` or a random suffix for those resources.
  EC2 instances do not have this problem; the `Name` tag does not need to be
  unique.
- **It spreads to dependencies.** If a resource with
  `create_before_destroy = true` depends on another resource that is also
  being replaced, Terraform uses create-before-destroy for that resource too.
- **No gap does not mean no downtime.** The new instance exists before the old
  one is removed, but traffic does not move automatically. Combine this with a
  load balancer or an Elastic IP to switch traffic to the new instance.
- **The current state is empty.** The instance from this exercise
  (`i-092c4087057ffd938`) has already been destroyed, so nothing is running.

## Key Takeaways

- By default, Terraform replaces a resource by destroying it first and then
  creating the new one (`-/+`).
- `create_before_destroy = true` reverses the order (`+/-`), so there is no
  gap without the resource.
- During the replacement, the old object is called a **deposed object**.
- It only affects replacements, not in-place updates or `terraform destroy`.
- Watch out for unique name conflicts, because both objects exist at the same
  time.
