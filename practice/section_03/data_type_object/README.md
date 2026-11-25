# The `object` Data Type in Terraform

This example demonstrates how to declare an input variable of type
[`object`](https://developer.hashicorp.com/terraform/language/expressions/types#object),
set its value in `terraform.tfvars`, and show it as an output.

The scenario: a variable describes a server with two named attributes, `name`
and `env`. No providers or resources are used; the object is only read and
returned as an output.

## Files

| File               | Purpose                                                  |
| ------------------ | -------------------------------------------------------- |
| `variables.tf`     | Declares the `server` variable of type `object({...})`.  |
| `terraform.tfvars` | Sets `server` to an object with `name` and `env`.        |
| `outputs.tf`       | Exposes the `server` variable as the `server` output.    |

## The Configuration

### `variables.tf`

```hcl
variable "server" {
  type = object({
    name = string
    env  = string
  })
  description = "Server info"
}
```

An `object` type lists **each attribute and its type**. Here the object must
have:

- `name`, a `string`
- `env`, a `string`

When each attribute is on its own line, no commas are needed. On a single line,
separate them with commas: `object({ name = string, env = string })`.

### `terraform.tfvars`

```hcl
server = {
  name = "server01"
  env  = "dev"
}
```

An object value is written in curly braces, like a map. Terraform loads
`terraform.tfvars` automatically.

### `outputs.tf`

```hcl
output "server" {
  value = var.server
}
```

## What Is an Object?

An object is a group of **named attributes**, where:

- the **attribute names are fixed** by the type,
- **each attribute has its own type** (for example, `name = string`,
  `cpu = number`, `public = bool`),
- every attribute in the type is **required**, unless it is marked
  `optional()`,
- attributes are accessed with `.name` or `["name"]`.

| Attribute | Expression                                  | Value        |
| --------- | ------------------------------------------- | ------------ |
| `name`    | `var.server.name` or `var.server["name"]` | `"server01"` |
| `env`     | `var.server.env` or `var.server["env"]`   | `"dev"`      |

### Object vs. map

|                      | `object({ name = string, env = string })` | `map(string)`                     |
| -------------------- | ----------------------------------------- | --------------------------------- |
| Keys                 | Fixed, decided by the type                | Any, decided by the value         |
| Value types          | Each attribute can have its own type      | All the same                      |
| Missing keys         | Error (unless `optional()`)               | Allowed                           |
| Extra keys           | Silently dropped                          | Kept                              |
| Typical use          | Structured settings with known fields     | Tags, lookups, name → value lists |

### Object vs. tuple

An `object` is to a `map` what a `tuple` is to a `list`: both allow **different
types** per element, but an object uses **names** and a tuple uses
**positions** (`tuple([string, number])`).

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

server = {
  "env" = "dev"
  "name" = "server01"
}
```

Unlike a list (`tolist([...])`) or a map (`tomap({...})`), an object is shown
without a conversion function.

### 3. Read the output

```bash
terraform output server
terraform output -json server
# {"env":"dev","name":"server01"}
```

### 4. Work with the object in the console

```bash
terraform console
```

| Expression                                   | Result                                         |
| -------------------------------------------- | ---------------------------------------------- |
| `var.server.name`                           | `"server01"`                                   |
| `var.server["env"]`                         | `"dev"`                                        |
| `type(var.server)`                          | `object({ env: string, name: string })`        |
| `keys(var.server)`                          | `["env", "name"]`                              |
| `length(var.server)`                        | `2`                                            |
| `lookup(var.server, "region", "us-east-1")` | `"us-east-1"` (default, the attribute does not exist) |
| `merge(var.server, {cpu = 2})`              | `{cpu = 2, env = "dev", name = "server01"}`    |

An attribute that is not in the type is an error:

```text
> var.server.region
Error: Unsupported attribute
This object does not have an attribute named "region".
```

Exit the console with `exit` or `Ctrl+D`.

### 5. Try other values

Values passed with `-var` override `terraform.tfvars`.

**Missing attribute**: error.

```text
$ terraform plan -var 'server={name="s1"}'
Error: Invalid value for input variable
Unsuitable value for var.server set using -var="server=...": attribute "env"
is required.
```

**Wrong type that cannot be converted**: error.

```text
$ terraform plan -var 'server={name=["a"], env="dev"}'
Error: Invalid value for input variable
Unsuitable value for var.server set using -var="server=...": attribute
"name": string required, but have tuple.
```

**Numbers and booleans**: converted to strings.

```bash
terraform plan -var 'server={name=1, env=true}'
# server = { env = "true", name = "1" }
```

**Extra attribute**: accepted, but **silently dropped**.

```bash
terraform plan -var 'server={name="s1", env="prod", cpu=2}'
# server = { env = "prod", name = "s1" }   (no cpu)
```

## Optional Attributes

Attributes can be made optional with `optional(type, default)`:

```hcl
variable "server" {
  type = object({
    name = string
    env  = optional(string, "dev")
    cpu  = optional(number)
  })
}
```

With `-var 'server={name="s1"}'`, the result is
`{ name = "s1", env = "dev", cpu = null }`: `env` gets its default value, and
`cpu` (no default) is `null`.

## Key Takeaways

- `object({ attr = type, ... })` groups named attributes, each with its own
  type.
- All attributes are required unless marked `optional()`; `optional()` can set
  a default value.
- Extra attributes are dropped without an error, and values are converted to
  the declared type when possible.
- Access attributes with `var.obj.attr` or `var.obj["attr"]`; unknown
  attributes are errors.
- Use `object` for structured settings with known fields, and `map` when the
  keys are not known in advance.
