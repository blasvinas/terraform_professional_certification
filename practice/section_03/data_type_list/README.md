# The `list` Data Type in Terraform

This example demonstrates how to declare an input variable of type
[`list`](https://developer.hashicorp.com/terraform/language/expressions/types#list),
set its value in `terraform.tfvars`, and show it as an output.

The scenario: a variable holds the names of three servers. No providers or
resources are used; the list is only read and returned as an output.

## Files

| File               | Purpose                                                 |
| ------------------ | ------------------------------------------------------- |
| `variables.tf`     | Declares the `servers` variable of type `list(string)`. |
| `terraform.tfvars` | Sets `servers` to three server names.                   |
| `outputs.tf`       | Exposes the `servers` variable as an output.            |

## The Configuration

### `variables.tf`

```hcl
variable "servers" {
  type        = list(string)
  description = "List of servers"
}
```

`list(string)` means "an ordered list where every element is a string".

### `terraform.tfvars`

```hcl
servers = ["server01", "server02", "server03"]
```

A list is written in square brackets, with elements separated by commas.
Terraform loads `terraform.tfvars` automatically.

### `outputs.tf`

```hcl
output "servers" {
  value = var.servers
}
```

## What Is a List?

A list is a sequence of values that:

- keeps its **order**: `server01` is always first,
- is **indexed from 0**: `var.servers[0]` is `"server01"`,
- can contain **duplicates**: `["a", "a"]` is a valid list,
- has **one element type**: in `list(string)`, every element is a string.

| Index | Expression       | Value        |
| ----- | ---------------- | ------------ |
| 0     | `var.servers[0]` | `"server01"` |
| 1     | `var.servers[1]` | `"server02"` |
| 2     | `var.servers[2]` | `"server03"` |

### Related collection types

| Type          | Ordered | Duplicates | Access by        | Example                    |
| ------------- | ------- | ---------- | ---------------- | -------------------------- |
| `list(type)`  | Yes     | Yes        | Index (`[0]`)    | `["a", "b", "a"]`          |
| `set(type)`   | No      | No         | Loop only        | `toset(["a", "b"])`        |
| `map(type)`   | No (sorted by key) | Keys are unique | Key (`["name"]`) | `{ a = 1, b = 2 }` |
| `tuple([...])`| Yes     | Yes        | Index            | `["a", 1, true]` (mixed types) |

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

No infrastructure is created; only the output is saved in the state:

```text
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

servers = tolist([
  "server01",
  "server02",
  "server03",
])
```

`tolist([...])` shows that the value is a real `list` (not a `tuple`), because
the variable declares the type `list(string)`.

### 3. Read the output

```bash
terraform output servers
terraform output -json servers
# ["server01","server02","server03"]
```

### 4. Work with the list in the console

```bash
terraform console
```

| Expression                                   | Result                                     |
| -------------------------------------------- | ------------------------------------------ |
| `var.servers[0]`                             | `"server01"`                               |
| `var.servers[length(var.servers) - 1]`       | `"server03"` (last element)                |
| `length(var.servers)`                        | `3`                                        |
| `index(var.servers, "server02")`             | `1`                                        |
| `contains(var.servers, "server02")`          | `true`                                     |
| `element(var.servers, 4)`                    | `"server02"` (wraps around: 4 % 3 = 1)     |
| `slice(var.servers, 0, 2)`                   | `["server01", "server02"]`                 |
| `concat(var.servers, ["server04"])`          | `["server01", "server02", "server03", "server04"]` |
| `reverse(var.servers)`                       | `["server03", "server02", "server01"]`     |
| `join(", ", var.servers)`                    | `"server01, server02, server03"`           |
| `[for s in var.servers : upper(s)]`          | `["SERVER01", "SERVER02", "SERVER03"]`     |

Invalid indexes are errors:

```text
> var.servers[3]
Error: Invalid index
The given key does not identify an element in this collection value: the
given index is greater than or equal to the length of the collection.

> var.servers[-1]
Error: Invalid index
The given key does not identify an element in this collection value: a
negative number is not a valid index for a sequence.
```

Exit the console with `exit` or `Ctrl+D`.

### 5. Try other values

Values passed with `-var` override `terraform.tfvars`:

```bash
terraform plan -var 'servers=["web01", "web02"]'
```

Terraform converts elements to `string` when it can:

```bash
terraform plan -var 'servers=["a", 1, true]'
# servers = ["a", "1", "true"]
```

Values that cannot be converted are rejected:

```text
$ terraform plan -var 'servers="server01"'
Error: Invalid value for input variable
Unsuitable value for var.servers set using -var="servers=...": list of string
required, but have string.

$ terraform plan -var 'servers=[["a"]]'
Error: Invalid value for input variable
Unsuitable value for var.servers set using -var="servers=...": element 0:
string required, but have tuple.
```

An empty list (`-var 'servers=[]'`) is also valid.

## Key Takeaways

- `list(type)` is an ordered collection of values of the same type.
- Elements are accessed by index, starting at `0`; negative or too large
  indexes are errors.
- Terraform converts values to the declared element type when possible (for
  example, `1` becomes `"1"`), and rejects values it cannot convert.
- Useful list functions: `length()`, `index()`, `contains()`, `element()`,
  `slice()`, `concat()`, `reverse()`, `join()`.
- `for` expressions create new lists from existing ones.
- Lists are commonly used with `count` to create several similar resources,
  for example `count = length(var.servers)` and
  `name = var.servers[count.index]`.
