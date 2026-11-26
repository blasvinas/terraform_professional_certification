# Creating Multiple Resources with `for_each`

This example demonstrates how to use the
[`for_each`](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each)
meta-argument to create **one resource per element** of a set or a map.

The scenario: we need three EC2 instances, `server01`, `server02` and
`server03`. The files contain two versions of the solution:

1. **Set version** (commented out): a `set(string)` of names. All instances
   share the same AMI and instance type.
2. **Map version** (active): a `map(object({...}))`. Each instance has its own
   AMI and instance type.

Unlike [`count`](../count/README.md), `for_each` identifies each instance by a
**key** (its name), not by a position.

## Files

| File                  | Purpose                                                              |
| --------------------- | -------------------------------------------------------------------- |
| `versions.tf`         | Pins the AWS provider (`hashicorp/aws` `6.74.0`).                    |
| `providers.tf`        | Configures the AWS provider for the `us-east-1` region.              |
| `variables.tf`        | Declares the `servers` variable (set version commented out, map version active). |
| `terraform.tfvars`    | Sets the values for both versions (set version commented out).       |
| `main.tf`             | Defines the `aws_instance` resource with `for_each` (both versions). |
| `.terraform.lock.hcl` | Dependency lock file created by `terraform init`.                    |

## `each.key` and `each.value`

Inside a block with `for_each`, the `each` object describes the current
element:

| `for_each` over      | `each.key`              | `each.value`                       |
| -------------------- | ----------------------- | ---------------------------------- |
| A set of strings     | The element             | The same element                   |
| A map                | The map key             | The value for that key             |

## Version 1: `for_each` with a Set (commented out)

### `variables.tf`

```hcl
variable "servers" {
  type        = set(string)
  description = "Servers"
}

variable "ami_id" {
  type        = string
  description = "AMI ID"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
}
```

### `terraform.tfvars`

```hcl
servers       = ["server01", "server02", "server03"]
ami_id        = "ami-0aacbf72109c53c0c"
instance_type = "t3.micro"
```

### `main.tf`

```hcl
resource "aws_instance" "servers" {
  for_each      = var.servers
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    "Name" = each.value
  }
}
```

- `for_each = var.servers` creates one instance per name in the set.
- For a set, `each.key` and `each.value` are the same, so `each.value` here is
  the server name.
- All instances use the same `ami_id` and `instance_type`.

## Version 2: `for_each` with a Map of Objects (active)

### `variables.tf`

```hcl
variable "servers" {
  type = map(object({
    ami_id        = string,
    instance_type = string
  }))
}
```

Each key of the map is a server name; each value is an object with that
server's settings.

### `terraform.tfvars`

```hcl
servers = {
  "server01" = {
    ami_id        = "ami-0aacbf72109c53c0c"
    instance_type = "t3.micro"
  },
  "server02" = {
    ami_id        = "ami-0aacbf72109c53c0c"
    instance_type = "t3.micro"
  },
  "server03" = {
    ami_id        = "ami-0aacbf72109c53c0c"
    instance_type = "t3.micro"
  },
}
```

### `main.tf`

```hcl
resource "aws_instance" "servers" {
  for_each      = var.servers
  ami           = each.value.ami_id
  instance_type = each.value.instance_type

  tags = {
    "Name" = each.key
  }
}
```

- `each.key` is the server name (`server01`, ...), used for the `Name` tag.
- `each.value` is that server's object, so `each.value.ami_id` and
  `each.value.instance_type` can be different for every server.

## Resource Addresses

With `for_each`, the resource becomes a **map** of instances. Each one has an
address with its key, in both versions:

| Address                            | `Name` tag |
| ---------------------------------- | ---------- |
| `aws_instance.servers["server01"]` | `server01` |
| `aws_instance.servers["server02"]` | `server02` |
| `aws_instance.servers["server03"]` | `server03` |

To refer to them elsewhere in the configuration:

| Expression                                               | Result                                   |
| -------------------------------------------------------- | ---------------------------------------- |
| `aws_instance.servers["server02"].id`                    | The ID of `server02`                     |
| `keys(aws_instance.servers)`                             | `["server01", "server02", "server03"]`   |
| `values(aws_instance.servers)[*].id`                     | A list with the IDs of all instances     |
| `{ for k, s in aws_instance.servers : k => s.id }`       | A map of name → ID                       |

Numeric indexes do not work, because the instances are keyed by name:

```text
Error: Invalid index
The given key does not identify an element in this collection value. An
object only supports looking up attributes by name, not by numeric index.
```

`aws_instance.servers[*].id` does not work either; use
`values(aws_instance.servers)[*].id`.

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

With the map version, each instance gets its settings from its own object:

```text
  # aws_instance.servers["server01"] will be created
      + ami           = "ami-0aacbf72109c53c0c"
      + instance_type = "t3.micro"
      + tags          = {
          + "Name" = "server01"
        }
  # aws_instance.servers["server02"] will be created
      ...
  # aws_instance.servers["server03"] will be created
      ...

Plan: 3 to add, 0 to change, 0 to destroy.
```

The set version produces the same three addresses.

### 3. Apply and list the instances

```bash
terraform apply
terraform state list
```

```text
aws_instance.servers["server01"]
aws_instance.servers["server02"]
aws_instance.servers["server03"]
```

Show a single instance with:

```bash
terraform state show 'aws_instance.servers["server02"]'
```

Use single quotes around the address, because it contains `[`, `]` and `"`.

### 4. Remove or change one server

- **Remove `server02`** from `terraform.tfvars`: only that instance is
  destroyed. The others keep their keys and are not touched:

  ```text
    # aws_instance.servers["server02"] will be destroyed
    # (because key ["server02"] is not in for_each map)

  Plan: 0 to add, 0 to change, 1 to destroy.
  ```

- **Change one server's settings** (map version), for example the
  `instance_type` of `server03`: only `aws_instance.servers["server03"]` is
  changed.

With `count`, removing an element from the middle of a list shifts the indexes
and changes every following instance. With `for_each`, each instance is
independent.

### 5. Switch between the versions (optional)

Comment out the map version and uncomment the set version in **all three**
files (`variables.tf`, `terraform.tfvars`, `main.tf`), then run
`terraform plan`. The addresses are the same, so Terraform only plans changes
for attributes that differ.

### 6. Clean up

```bash
terraform destroy
```

## `for_each` vs. `count`

|                               | `count`                          | `for_each`                              |
| ----------------------------- | -------------------------------- | --------------------------------------- |
| Input                         | A whole number                   | A map, or a set of strings              |
| Instance address              | `resource[0]`                    | `resource["key"]`                       |
| Current element               | `count.index`                    | `each.key`, `each.value`                |
| Removing an item from the middle | Shifts indexes, changes others | Affects only that item                |
| Different settings per item   | Needs a separate list + index    | Natural with a map of objects           |
| Best for                      | N identical copies, or `0`/`1` to make a resource optional | Items with their own identity |

## Notes

- **Lists are not accepted.** `for_each` needs a map or a set of strings. With
  a `list(string)` variable, Terraform fails:

  ```text
  Error: Invalid for_each argument
  The given "for_each" argument value is unsuitable: the "for_each" argument
  must be a map, or set of strings, and you have provided a value of type list
  of string.
  ```

  Convert it with `for_each = toset(var.servers)`.
- **Keys must be known at plan time.** The keys cannot depend on values that
  are only known after apply (such as the ID of a resource being created).
- **Sensitive values cannot be used** as `for_each` keys.
- **Style.** The commas in the `object({...})` type and between the map entries
  in `terraform.tfvars` are optional when each item is on its own line. The
  quotes around simple keys (`"server01"`, `"Name"`) are also optional. The
  map-version variable has no `description`.
- **Nothing is running.** The current state is empty; the three instances from
  this exercise have been destroyed.

## Key Takeaways

- `for_each` creates one instance per element of a map or a set of strings.
- Use `each.key` and `each.value` to configure each instance; for a set, both
  are the element.
- A map of objects lets each instance have its own settings.
- Instances are addressed by key (`resource["key"]`), so removing one item
  does not affect the others.
- Use `values(resource)[*].attr` or a `for` expression to collect attributes
  from all instances.
- Prefer `for_each` over `count` when items have their own identity.
