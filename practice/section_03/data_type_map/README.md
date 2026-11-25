# The `map` Data Type in Terraform

This example demonstrates how to declare an input variable of type
[`map`](https://developer.hashicorp.com/terraform/language/expressions/types#map),
set its value in `terraform.tfvars`, and show it as an output.

The scenario: a variable holds information about a server (its name and
environment) as key/value pairs. No providers or resources are used; the map is
only read and returned as an output.

## Files

| File               | Purpose                                                  |
| ------------------ | -------------------------------------------------------- |
| `variables.tf`     | Declares the `servers` variable of type `map(string)`.   |
| `terraform.tfvars` | Sets `servers` to a map with the keys `name` and `env`.  |
| `outputs.tf`       | Exposes the `servers` variable as an output.             |

## The Configuration

### `variables.tf`

```hcl
variable "servers" {
  type        = map(string)
  description = "Servers info"
}
```

`map(string)` means "a map where every value is a string". Terraform checks
this when the variable is set.

You may also see `type = map`. That is the old shorthand for `map(any)`: a map
whose values can be any **single** type, chosen from the value it receives.
`terraform fmt` rewrites `map` to `map(any)`. An explicit element type such as
`map(string)` is clearer and is checked by Terraform.

### `terraform.tfvars`

```hcl
servers = {
  name = "server01"
  env  = "dev"
}
```

A map is written in curly braces as `key = value` pairs, one per line.
Terraform also accepts `key : value`, commas between the pairs, and quoted keys
(`"name" : "server01",`), but the form above is the usual Terraform style.
Quotes are only needed for keys that are not valid identifiers, such as
`"my-key.1"`.

Terraform loads `terraform.tfvars` automatically.

### `outputs.tf`

```hcl
output "servers" {
  value = var.servers
}
```

## What Is a Map?

A map is a collection of **key/value pairs** where:

- every **key** is a string and is **unique**,
- every **value** has the **same type** (for example, all strings),
- elements are accessed **by key**, not by position,
- the elements are always **sorted by key** when shown (`env` comes before
  `name`).

| Key    | Expression                                  | Value        |
| ------ | ------------------------------------------- | ------------ |
| `name` | `var.servers["name"]` or `var.servers.name` | `"server01"` |
| `env`  | `var.servers["env"]` or `var.servers.env`   | `"dev"`      |

### Map vs. object

|                     | `map(string)`                  | `object({ name = string, env = string })` |
| ------------------- | ------------------------------ | ----------------------------------------- |
| Keys                | Any, decided by the value      | Fixed, decided by the type                |
| Value types         | All the same                   | Each attribute can have its own type      |
| Missing / extra keys | Allowed                       | Missing attributes are errors (unless `optional()`) |
| Typical use         | Tags, lookups, name → value lists | Structured settings with known fields  |

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

servers = tomap({
  "env" = "dev"
  "name" = "server01"
})
```

`tomap({...})` shows that the value is a real `map`. The keys are sorted, so
`env` is shown before `name`, even though `name` comes first in
`terraform.tfvars`.

### 3. Read the output

```bash
terraform output servers
terraform output -json servers
# {"env":"dev","name":"server01"}
```

### 4. Work with the map in the console

```bash
terraform console
```

| Expression                                            | Result                                                     |
| ----------------------------------------------------- | ---------------------------------------------------------- |
| `var.servers["name"]`                                 | `"server01"`                                               |
| `var.servers.env`                                     | `"dev"`                                                    |
| `type(var.servers)`                                   | `map(string)`                                              |
| `length(var.servers)`                                 | `2`                                                        |
| `keys(var.servers)`                                   | `["env", "name"]`                                          |
| `values(var.servers)`                                 | `["dev", "server01"]`                                      |
| `contains(keys(var.servers), "env")`                  | `true`                                                     |
| `lookup(var.servers, "region", "us-east-1")`          | `"us-east-1"` (default, because the key does not exist)    |
| `merge(var.servers, {env = "prod", owner = "blas"})`  | `{env = "prod", name = "server01", owner = "blas"}`        |
| `{for k, v in var.servers : k => upper(v)}`           | `{env = "DEV", name = "SERVER01"}`                         |
| `[for k, v in var.servers : "${k}=${v}"]`             | `["env=dev", "name=server01"]`                             |

A key that does not exist is an error (use `lookup()` with a default instead):

```text
> var.servers["region"]
Error: Invalid index
The given key does not identify an element in this collection value.
```

Exit the console with `exit` or `Ctrl+D`.

### 5. Try other values

Values passed with `-var` override `terraform.tfvars`. Numbers and booleans are
converted to strings, because the type is `map(string)`:

```bash
terraform plan -var 'servers={name="s1", cpu=2, on=true}'
# servers = { cpu = "2", name = "s1", on = "true" }
```

Values that cannot be converted to a string, or values that are not a map, are
rejected:

```text
$ terraform plan -var 'servers={name="s1", tags=["a"]}'
Error: Invalid value for input variable
Unsuitable value for var.servers set using -var="servers=...": element
"tags": string required, but have tuple.

$ terraform plan -var 'servers=["a"]'
Error: Invalid value for input variable
Unsuitable value for var.servers set using -var="servers=...": map of string
required.
```

## Key Takeaways

- `map(type)` is a collection of unique string keys whose values all have the
  same type.
- Access values with `var.map["key"]` or `var.map.key`; a missing key is an
  error, so use `lookup(map, key, default)` when a key may be missing.
- Maps are always shown sorted by key.
- Useful map functions: `keys()`, `values()`, `length()`, `lookup()`,
  `merge()`.
- `for` expressions can turn a map into a new map (`{for k, v in ... : k => v}`)
  or a list (`[for k, v in ... : ...]`).
- Maps are commonly used for resource `tags` and with `for_each` to create one
  resource per key.
