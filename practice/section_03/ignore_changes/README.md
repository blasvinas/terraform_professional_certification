# Ignoring Changes with `lifecycle { ignore_changes }`

This example demonstrates how to use the
[`ignore_changes`](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#ignore_changes)
lifecycle argument to stop Terraform from undoing changes that were made
**outside of Terraform**.

The scenario: Terraform creates an EC2 instance with the tag
`Name = "server01"`. Later, someone adds a `Department` tag in the AWS Console.
Normally, the next `terraform apply` would remove that tag, because it is not in
the code. With `ignore_changes = [tags]`, Terraform leaves the tags alone.

## Files

| File                  | Purpose                                                          |
| --------------------- | ---------------------------------------------------------------- |
| `versions.tf`         | Pins the AWS provider (`hashicorp/aws` `6.74.0`).                |
| `providers.tf`        | Configures the AWS provider for the `us-east-1` region.          |
| `variables.tf`        | Declares the `ami_id` and `instance_type` input variables.       |
| `terraform.tfvars`    | Sets the variable values (an AMI ID and `t3.micro`).             |
| `main.tf`             | Defines the `aws_instance` with `ignore_changes` on `tags`.      |
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
    ignore_changes = ["tags"]
  }
}
```

- **`lifecycle`**: a meta-argument block that changes how Terraform handles a
  resource. It works with every resource type.
- **`ignore_changes`**: a list of attributes. When Terraform compares the real
  object with the configuration, differences in these attributes are ignored.
- The attribute is still used when the resource is **created**. Here the
  instance is created with `Name = "server01"`; after that, `tags` is never
  updated again.

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

## `ignore_changes` Options

| Value                              | Effect                                                        |
| ---------------------------------- | ------------------------------------------------------------- |
| `[tags]`                           | Ignore all changes to the `tags` map.                         |
| `[tags["Department"]]`             | Ignore only the `Department` tag; other tags are still managed. |
| `[ami, user_data]`                 | Ignore several attributes.                                    |
| `all`                              | Ignore changes to **every** attribute (only create and destroy). |

Attributes are written as plain references (`tags`), not as strings
(`"tags"`). See [Notes](#notes).

## Prerequisites

- Terraform installed
- An AWS account with credentials configured (for example `aws configure`, or
  the `AWS_PROFILE` / `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` environment
  variables)
- A default VPC in `us-east-1` (no subnet is set, so AWS uses the default VPC)

> **Cost:** this example launches a real EC2 instance. Destroy it when you are
> done.

## Step-by-Step Process

### 1. Initialize and create the instance

```bash
terraform init
terraform apply
```

The instance is created with the tag `Name = "server01"`.

### 2. Change the tags outside of Terraform

In the AWS Console (EC2 → Instances → `server01` → Tags → Manage tags), add a
tag, or use the AWS CLI:

```bash
aws ec2 create-tags \
  --resources <instance-id> \
  --tags Key=Department,Value=Development
```

Get the instance ID with `terraform state show aws_instance.server01`.

### 3. Run a plan

```bash
terraform plan
```

Terraform reads the new tag from AWS but ignores the difference:

```text
aws_instance.server01: Refreshing state... [id=i-0d5a9972afea3c000]

No changes. Your infrastructure matches the configuration.
```

### 4. Compare with a plan without `ignore_changes`

Remove the `lifecycle` block (or set `ignore_changes = []`) and run
`terraform plan` again. Terraform now wants to remove the tag that was added
outside of Terraform:

```text
  # aws_instance.server01 will be updated in-place
  ~ resource "aws_instance" "server01" {
      ~ tags                                 = {
          - "Department" = "Developtment" -> null
            "Name"       = "server01"
        }
      ~ tags_all                             = {
          - "Department" = "Developtment" -> null
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

Put the `lifecycle` block back afterwards.

### 5. Changes in the code are ignored too

With `ignore_changes = [tags]`, changing the tags **in `main.tf`** (for example
`Name = "web01"`) also gives `No changes`. To ignore only the tag managed
outside of Terraform and keep managing the rest, use:

```hcl
lifecycle {
  ignore_changes = [tags["Department"]]
}
```

Now the `Name` change is applied, and the `Department` tag is kept:

```text
      ~ tags                                 = {
            "Department" = "Developtment"
          ~ "Name"       = "server01" -> "web01"
        }
```

### 6. Clean up

```bash
terraform destroy
```

## Notes

- **Quoted references are deprecated.** `ignore_changes = ["tags"]` still
  works, but Terraform shows this warning on every run:

  ```text
  Warning: Quoted references are deprecated

    on main.tf line 10, in resource "aws_instance" "server01":
    10:     ignore_changes = ["tags"]
  ```

  Write `ignore_changes = [tags]` instead.
- **The `Department` tag value has a typo.** The tag added in AWS is
  `Developtment` (should be `Development`). It is outside of Terraform, so fix
  it in the AWS Console or with `aws ec2 create-tags`.
- **The instance is still running.** The state shows the instance
  `i-0d5a9972afea3c000` as `running`. Run `terraform destroy` when you no
  longer need it, to avoid charges.
- **Use `ignore_changes` carefully.** Ignored attributes can drift from the
  code without any warning. Ignore only what is really managed elsewhere (for
  example, tags set by another team, or an auto scaling group's
  `desired_capacity`).

## Key Takeaways

- `ignore_changes` tells Terraform to ignore differences in the listed
  attributes after the resource is created.
- It ignores changes made outside of Terraform **and** changes made in the
  code.
- Use map keys (`tags["Department"]`) to ignore only part of an attribute.
- `ignore_changes = all` ignores every attribute.
- Write attributes as references (`tags`), not strings (`"tags"`).
