# Nesting Types in Terraform

This example demonstrates how to combine Terraform's
[complex types](https://developer.hashicorp.com/terraform/language/expressions/type-constraints#complex-types)
by putting types inside other types: a **list of objects**, where each object
contains a **string**, a **list**, and a **map**.

The scenario: a variable describes several servers. Each server has a name, a
list of IP addresses, and a map of tags. No providers or resources are used;
the value is only read and returned as an output.

## Files

| File               | Purpose                                                          |
| ------------------ | ---------------------------------------------------------------- |
| `variables.tf`     | Declares the `servers` variable of type `list(object({...}))`.   |
| `terraform.tfvars` | Sets `servers` to two servers.                                   |
| `outputs.tf`       | Exposes the `servers` variable as an output.                     |

## The Configuration

### `variables.tf`

```hcl
variable "servers" {
  type = list(object({
    name = string
    ips  = list(string)
    tags = map(string)
  }))
  description = "List of servers, each with a name, IP addresses and tags"
}
```

Read the type from the outside in:

```text
list(                      a list ...
  object({                 ... of objects, each with:
    name = string            - name: a string
    ips  = list(string)      - ips:  a list of strings
    tags = map(string)       - tags: a map of strings
  })
)
```

### `terraform.tfvars`

```hcl
servers = [
  {
    name = "server01"
    ips  = ["10.1.1.1", "10.1.1.2"]
    tags = {
      env   = "dev"
      owner = "John"
    }
  },
  {
    name = "server02"
    ips  = ["10.1.1.3", "10.1.1.4"]
    tags = {
      env   = "prod"
      owner = "Bob"
    }
  }
]
```

The value has the same shape as the type: square brackets for the list, and
curly braces for each object and each map.

- The comma **between the two servers** is required, because they are elements
  of a list.
- Attributes and map entries that are each on their own line need no commas.
- Map keys such as `env` need no quotes, because they are simple names. Quotes
  are only needed for keys with characters such as `.` or `/`, for example
  `"kubernetes.io/role"`. Terraform loads `terraform.tfvars`
automatically.

### `outputs.tf`

```hcl
output "servers" {
  value = var.servers
}
```

## Accessing Nested Values

Chain the access operators from the outside in: `[index]` for lists, `.attr`
for objects, and `["key"]` (or `.key`) for maps.

| Expression                     | Steps                                       | Result       |
| ------------------------------ | ------------------------------------------- | ------------ |
| `var.servers[0].name`          | 1st server → `name`                         | `"server01"` |
| `var.servers[1].ips[0]`        | 2nd server → `ips` → 1st IP                 | `"10.1.1.3"` |
| `var.servers[0].tags["owner"]` | 1st server → `tags` → `owner` key           | `"John"`     |
| `var.servers[1].tags.env`      | 2nd server → `tags` → `env` key             | `"prod"`     |

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
Outputs:

servers = tolist([
  {
    "ips" = tolist([
      "10.1.1.1",
      "10.1.1.2",
    ])
    "name" = "server01"
    "tags" = tomap({
      "env" = "dev"
      "owner" = "John"
    })
  },
  {
    "ips" = tolist([
      "10.1.1.3",
      "10.1.1.4",
    ])
    "name" = "server02"
    "tags" = tomap({
      "env" = "prod"
      "owner" = "Bob"
    })
  },
])
```

`tolist()` and `tomap()` mark the lists and maps; the objects are shown as
plain `{ ... }`. The attributes and map keys are sorted alphabetically.

### 3. Read the output

```bash
terraform output -json servers
```

```json
[{"ips":["10.1.1.1","10.1.1.2"],"name":"server01","tags":{"env":"dev","owner":"John"}},{"ips":["10.1.1.3","10.1.1.4"],"name":"server02","tags":{"env":"prod","owner":"Bob"}}]
```

Pipe it to `jq` to make it easier to read, for example
`terraform output -json servers | jq '.[].name'`.

### 4. Work with the nested value in the console

```bash
terraform console
```

| Expression                                                   | Result                                              |
| ------------------------------------------------------------ | --------------------------------------------------- |
| `type(var.servers)`                                          | `list(object({ ips: list(string), name: string, tags: map(string) }))` |
| `length(var.servers)`                                        | `2`                                                 |
| `var.servers[*].name`                                        | `["server01", "server02"]`                          |
| `flatten(var.servers[*].ips)`                                | `["10.1.1.1", "10.1.1.2", "10.1.1.3", "10.1.1.4"]`  |
| `{for s in var.servers : s.name => s.tags.owner}`            | `{server01 = "John", server02 = "Bob"}`             |
| `[for s in var.servers : s.name if s.tags.env == "prod"]`    | `["server02"]`                                      |
| `{for s in var.servers : s.name => s}["server02"].ips`       | `["10.1.1.3", "10.1.1.4"]`                          |

- **`[*]` (splat)**: takes one attribute from every element of a list.
- **`flatten()`**: turns a list of lists into a single list.
- **`for ... : key => value`**: builds a map, here keyed by server name.
- **`for ... if ...`**: keeps only the elements that match a condition.

Exit the console with `exit` or `Ctrl+D`.

### 5. Try invalid values

Terraform checks the whole structure and reports exactly where the problem is:

```text
$ terraform plan -var 'servers=[{name="s1", ips=["10.0.0.1"]}]'
Error: Invalid value for input variable
Unsuitable value for var.servers set using -var="servers=...": element 0:
attribute "tags" is required.

$ terraform plan -var 'servers=[{name="s1", ips="10.0.0.1", tags={}}]'
Error: Invalid value for input variable
Unsuitable value for var.servers set using -var="servers=...": element 0:
attribute "ips": list of string required, but have string.
```

## Using a Nested Variable with `for_each`

`for_each` needs a map (or a set), so a list of objects is usually turned into
a map keyed by a unique attribute:

```hcl
resource "aws_instance" "server" {
  for_each = { for s in var.servers : s.name => s }

  ami           = var.ami_id
  instance_type = "t3.micro"
  private_ip    = each.value.ips[0]
  tags          = merge(each.value.tags, { Name = each.key })
}
```

This creates `aws_instance.server["server01"]` and
`aws_instance.server["server02"]`. (This snippet is an illustration; it is not
part of this example.)

## Key Takeaways

- Complex types can be nested: lists of objects, maps of lists, objects with
  maps, and so on.
- Read nested types from the outside in, and write values in the same shape.
- Access nested values by chaining `[index]`, `.attribute` and `["key"]`.
- Use splat (`[*]`), `flatten()` and `for` expressions to extract and reshape
  nested data.
- Terraform validates the whole structure, and error messages point to the
  exact element and attribute.
- Convert a list of objects to a map (`{ for s in ... : s.name => s }`) to use
  it with `for_each`.
