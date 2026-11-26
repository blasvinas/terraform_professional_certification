# Creating Multiple Resources with `count`

This example demonstrates how to use the
[`count`](https://developer.hashicorp.com/terraform/language/meta-arguments/count)
meta-argument to create **several copies** of a resource from a single
`resource` block.

The scenario: we need three identical EC2 instances. Instead of writing three
`resource` blocks, one block with `count = 3` creates all of them, and
`count.index` gives each one a different `Name` tag (`server1`, `server2`,
`server3`).

## Files

| File                  | Purpose                                                          |
| --------------------- | ---------------------------------------------------------------- |
| `versions.tf`         | Pins the AWS provider (`hashicorp/aws` `6.74.0`).                |
| `providers.tf`        | Configures the AWS provider for the `us-east-1` region.          |
| `variables.tf`        | Declares the `ami_id` and `instance_type` input variables.       |
| `terraform.tfvars`    | Sets the variable values (an AMI ID and `t3.micro`).             |
| `main.tf`             | Defines the `aws_instance` resource with `count = 3`.            |
| `.terraform.lock.hcl` | Dependency lock file created by `terraform init`.                |

## The Configuration

### `main.tf`

```hcl
resource "aws_instance" "servers" {
  count         = 3
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "server${count.index + 1}"
  }
}
```

- **`count = 3`**: Terraform creates 3 instances from this block.
- **`count.index`**: the number of the current copy, starting at **0**
  (`0`, `1`, `2`). It can only be used inside a block that has `count`.
- **`"server${count.index + 1}"`**: adds 1 so the names start at 1:
  `server1`, `server2`, `server3`.

### `variables.tf` and `terraform.tfvars`

```hcl
variable "ami_id" {
  type        = string
  description = "AMI ID"
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

## Resource Addresses

With `count`, the resource becomes a **list** of instances. Each one has an
address with its index:

| Address                   | `count.index` | `Name` tag |
| ------------------------- | ------------- | ---------- |
| `aws_instance.servers[0]` | `0`           | `server1`  |
| `aws_instance.servers[1]` | `1`           | `server2`  |
| `aws_instance.servers[2]` | `2`           | `server3`  |

To refer to them elsewhere in the configuration:

| Expression                         | Result                                    |
| ---------------------------------- | ----------------------------------------- |
| `aws_instance.servers[0].id`       | The ID of the first instance              |
| `aws_instance.servers[*].id`       | A list with the IDs of all instances      |
| `length(aws_instance.servers)`     | `3`                                       |

`aws_instance.servers.id` (without an index) is an error, because there is more
than one instance:

```text
Error: Missing resource instance key

Because aws_instance.servers has "count" set, its attributes must be
accessed on specific instances.
```

## Prerequisites

- Terraform installed
- An AWS account with credentials configured (for example `aws configure`, or
  the `AWS_PROFILE` / `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` environment
  variables)
- A default VPC in `us-east-1` (no subnet is set, so AWS uses the default VPC)

> **Cost:** this example launches **three** real EC2 instances. Destroy them
> when you are done.

## Step-by-Step Process

### 1. Initialize the working directory

```bash
terraform init
```

### 2. Review the plan

```bash
terraform plan
```

One block produces three instances:

```text
  # aws_instance.servers[0] will be created
      + tags = {
          + "Name" = "server1"
        }
  # aws_instance.servers[1] will be created
      + tags = {
          + "Name" = "server2"
        }
  # aws_instance.servers[2] will be created
      + tags = {
          + "Name" = "server3"
        }

Plan: 3 to add, 0 to change, 0 to destroy.
```

### 3. Apply and list the instances

```bash
terraform apply
terraform state list
```

```text
aws_instance.servers[0]
aws_instance.servers[1]
aws_instance.servers[2]
```

Show a single instance with:

```bash
terraform state show 'aws_instance.servers[1]'
```

Quote the address, because `[` and `]` have a special meaning in most shells.

### 4. Change the count

- **Lower `count` (3 → 2)**: Terraform destroys the instance with the highest
  index:

  ```text
    # aws_instance.servers[2] will be destroyed
    # (because index [2] is out of range for count)
  ```

- **Raise `count` (3 → 4)**: Terraform creates `aws_instance.servers[3]`. The
  existing instances are not changed.

### 5. Clean up

```bash
terraform destroy
```

## Common `count` Patterns

### Use a variable instead of a fixed number

```hcl
variable "server_count" {
  type    = number
  default = 3
}

resource "aws_instance" "servers" {
  count = var.server_count
  # ...
}
```

### One instance per list element

```hcl
variable "names" {
  type    = list(string)
  default = ["web", "app", "db"]
}

resource "aws_instance" "servers" {
  count = length(var.names)
  # ...
  tags = {
    Name = var.names[count.index]
  }
}
```

### Create a resource only when a condition is true

```hcl
resource "aws_eip" "ip" {
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.servers[0].id
}
```

`count = 0` means the resource is not created at all.

## Notes

- **Removing an element from the middle of a list shifts the indexes.** With
  `names = ["web", "app", "db"]`, removing `"app"` does **not** remove
  `servers[1]`. Instead, `servers[1]` changes from `app` to `db`, and
  `servers[2]` is destroyed:

  ```text
    # terraform_data.named[1] will be updated in-place
        ~ input = "app" -> "db"
    # terraform_data.named[2] will be destroyed
    # (because index [2] is out of range for count)
  ```

  (Output from a test with the free `terraform_data` resource.) For an EC2
  instance, a change to an argument such as `ami` would even **replace** the
  instance. When each copy has its own identity, use
  [`for_each`](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each)
  with a map or set instead; its instances are tracked by key, not by position.
- **`count` must be known at plan time** and must be a whole number of `0` or
  more. A negative value fails with
  `must be greater than or equal to zero`. It cannot depend on attributes that
  are only known after apply (such as the ID of a resource being created).
- **The count is hard-coded.** `count = 3` works, but a variable
  (`count = var.server_count`) makes it easy to change the number without
  editing `main.tf`.
- **Nothing is running.** The current state is empty; the three instances from
  this exercise (`server1`–`server3`) have been destroyed.

## Key Takeaways

- `count = N` creates N copies of a resource from one block.
- `count.index` is the copy's number, starting at `0`.
- Instances are addressed as `resource[index]`; use `[*]` to get a list of all
  of them.
- Lowering `count` destroys the highest indexes; raising it adds new ones.
- `count = condition ? 1 : 0` creates a resource only when needed.
- Because instances are tracked by position, use `for_each` when items may be
  removed from the middle of the list.
