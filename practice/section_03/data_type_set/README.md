# The `set` Data Type in Terraform

This example demonstrates how to declare an input variable of type
[`set`](https://developer.hashicorp.com/terraform/language/expressions/types#set),
set its value in `terraform.tfvars`, and show it as an output.

The scenario: a variable holds server names, and the value in
`terraform.tfvars` contains `server01` **twice**. Because the variable is a set,
Terraform keeps only one copy, so the result has three unique names. No
providers or resources are used; the set is only read and returned as an
output.

## Files

| File               | Purpose                                                    |
| ------------------ | ---------------------------------------------------------- |
| `variables.tf`     | Declares the `servers` variable of type `set(string)`.     |
| `terraform.tfvars` | Sets `servers` to four names, one of them a duplicate.     |
| `outputs.tf`       | Exposes the `servers` variable as an output.               |

## The Configuration

### `variables.tf`

```hcl
variable "servers" {
  type        = set(string)
  description = "Servers"
}
```

`set(string)` means "a collection of **unique** strings, with no order".

### `terraform.tfvars`

```hcl
servers = ["server01", "server02", "server03", "server01"]
```

There is no special syntax for sets: the value is written like a list, in
square brackets. Terraform converts it to a set because of the variable's
type, and the second `"server01"` is removed. Terraform loads
`terraform.tfvars` automatically.

### `outputs.tf`

```hcl
output "servers" {
  value = var.servers
}
```

## What Is a Set?

A set is a collection of values that:

- has **no duplicates**: the same value is stored only once,
- has **no order** and **no index**: `var.servers[0]` is an error,
- has **one element type**: in `set(string)`, every element is a string,
- is **shown sorted** (strings alphabetically), no matter how it was written.

### Set vs. list

|                         | `list(string)`                  | `set(string)`                          |
| ----------------------- | ------------------------------- | -------------------------------------- |
| Duplicates              | Kept                            | Removed                                |
| Order                   | Kept as written                 | None (shown sorted)                    |
| Access one element      | By index: `var.x[0]`            | Not possible; only `contains()` or a loop |
| Shown as                | `tolist([...])`                 | `toset([...])`                         |
| Works with `for_each`   | No (convert with `toset()`)     | Yes                                    |

## Prerequisites

- Terraform installed

No providers, network access, or cloud credentials are required.

## Step-by-Step Process

### 1. Initialize the working directory

```bash
terraform init
```

### 2. Apply the configuration

```bash
terraform apply
```

No infrastructure is created; only the output is saved in the state. The four
names in `terraform.tfvars` become three:

```text
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

servers = toset([
  "server01",
  "server02",
  "server03",
])
```

`toset([...])` shows that the value is a real `set`.

### 3. Read the output

```bash
terraform output -json servers
# ["server01","server02","server03"]
```

JSON has no set type, so the set is written as a JSON array.

### 4. Work with the set in the console

```bash
terraform console
```

| Expression                                                  | Result                                     |
| ----------------------------------------------------------- | ------------------------------------------ |
| `type(var.servers)`                                         | `set(string)`                              |
| `length(var.servers)`                                       | `3`                                        |
| `contains(var.servers, "server02")`                         | `true`                                     |
| `tolist(var.servers)[0]`                                    | `"server01"` (convert to a list first)     |
| `setunion(var.servers, ["server04"])`                       | `["server01", "server02", "server03", "server04"]` |
| `setintersection(var.servers, ["server02", "server09"])`    | `["server02"]` (only values in both)       |
| `setsubtract(var.servers, ["server01"])`                    | `["server02", "server03"]`                 |
| `[for s in var.servers : upper(s)]`                         | `["SERVER01", "SERVER02", "SERVER03"]`     |
| `toset(["b", "a", "b", "c"])`                               | `["a", "b", "c"]` (duplicates removed, sorted) |

Sets have no index:

```text
> var.servers[0]
Error: Invalid index
Elements of a set are identified only by their value and don't have any
separate index or key to select with, so it's only possible to perform
operations across all elements of the set.
```

Exit the console with `exit` or `Ctrl+D`.

### 5. Try other values

The order you write the values in does not matter; the set is always sorted:

```bash
terraform plan -var 'servers=["zeta", "alpha", "mid"]'
# servers = ["alpha", "mid", "zeta"]
```

## Using a Set with `for_each`

Sets are commonly used with
[`for_each`](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each)
to create one resource per element. Each instance is identified by its
**value**, not by a position:

```hcl
resource "aws_instance" "server" {
  for_each = var.servers

  ami           = var.ami_id
  instance_type = "t3.micro"

  tags = {
    Name = each.key
  }
}
```

This plans `aws_instance.server["server01"]`, `["server02"]` and
`["server03"]`. Removing `server02` later destroys only
`aws_instance.server["server02"]`; the others are not affected. Compare this
with `count`, where removing an element from the middle shifts the indexes of
all following instances. (This snippet is an illustration; it is not part of
this example.)

## Key Takeaways

- `set(type)` is a collection of unique values with no order and no index.
- Duplicates are removed automatically when a value is converted to a set.
- Sets are written like lists (`[...]`) and are shown sorted as
  `toset([...])`.
- Use `contains()`, `length()`, `setunion()`, `setintersection()`,
  `setsubtract()`, or a `for` expression to work with sets; use `tolist()` if
  you need an index.
- Sets of strings work directly with `for_each`; each instance is keyed by its
  value.
