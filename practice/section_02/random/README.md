# Generating a Random Integer with the `random` Provider

This example demonstrates how to use the
[`hashicorp/random`](https://registry.terraform.io/providers/hashicorp/random/latest/docs)
provider to generate a random integer and expose it as an output value.

The `random` provider works entirely inside Terraform: it does not need cloud
credentials and does not create any external infrastructure. The generated value
is stored in the Terraform state, so it stays the same across later runs until
the resource is replaced.

## Files

| File                  | Purpose                                                              |
| --------------------- | -------------------------------------------------------------------- |
| `main.tf`             | Defines a `random_integer` resource between `1` and `100`.           |
| `outputs.tf`          | Outputs the generated value.                                         |
| `.terraform.lock.hcl` | Locks the `hashicorp/random` provider to version `3.9.1`.            |

> There is no `required_providers` block. Terraform infers `hashicorp/random`
> from the `random_` resource type prefix and installs the latest available
> version during `terraform init`.

## The Configuration

### `main.tf`

```hcl
resource "random_integer" "this" {
  min = 1
  max = 100
}
```

- **`min`** — the lowest possible value (inclusive).
- **`max`** — the highest possible value (inclusive).

### `outputs.tf`

```hcl
output "this" {
  value = random_integer.this.id
}
```

The output uses the resource's `id` attribute, which holds the generated number
as a **string** (for example, `"15"`). To get the value as a **number**, use
`random_integer.this.result` instead.

## Prerequisites

- Terraform installed
- Network access to the Terraform Registry (for `terraform init`)

No cloud credentials are required.

## Step-by-Step Process

### 1. Initialize the working directory

```bash
terraform init
```

This downloads the `hashicorp/random` provider and creates or updates
`.terraform.lock.hcl`.

### 2. Apply the configuration

```bash
terraform apply
```

Terraform creates the `random_integer.this` resource and prints the output:

```text
Outputs:

this = "15"
```

Your number will probably be different.

### 3. Read the output again

```bash
terraform output this
```

The value comes from the state, so it does not change. Running
`terraform apply` again also keeps the same value because the configuration has
not changed.

### 4. Generate a new value (optional)

To force Terraform to replace the resource and generate a new number:

```bash
terraform apply -replace="random_integer.this"
```

Changing `min` or `max` also makes Terraform replace the resource and generate
a new value.

### 5. Clean up

```bash
terraform destroy
```

## Key Takeaways

- The `random` provider generates values locally and stores them in state.
- Random values stay the same between runs until the resource is replaced.
- `random_integer.this.id` is a string; `random_integer.this.result` is a
  number.
- Use `-replace` (or change an argument that forces replacement, such as `min`,
  `max`, `keepers`, or `seed`) to generate a new value.
