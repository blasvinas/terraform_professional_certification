# Encoding and Decoding JSON with `jsonencode` and `jsondecode`

This example demonstrates how to use the built-in
[`jsonencode`](https://developer.hashicorp.com/terraform/language/functions/jsonencode)
and
[`jsondecode`](https://developer.hashicorp.com/terraform/language/functions/jsondecode)
functions to convert between Terraform values and JSON strings.

The scenario: an HCL object describing a person is encoded to a JSON string and
then decoded back into an object, showing that the two functions are inverses.
No providers or resources are used; everything happens in `locals` and outputs.

## Files

| File         | Purpose                                                          |
| ------------ | ---------------------------------------------------------------- |
| `main.tf`    | Defines the `person`, `person_json`, and `person_back` locals.   |
| `outputs.tf` | Exposes `person_json`, `person_back`, and `person_name` outputs. |

## The Configuration

### `main.tf`

```hcl
locals {
  person = {
    Name = "Blas"
    Age  = 55
  }

  person_json = jsonencode(local.person)
  person_back = jsondecode(local.person_json)
}
```

- **`person`** — an HCL object with two attributes.
- **`person_json`** — `jsonencode()` serializes the object into the JSON string
  `{"Age":55,"Name":"Blas"}` (keys are sorted alphabetically).
- **`person_back`** — `jsondecode()` parses the JSON string back into an object.

### `outputs.tf`

```hcl
output "person_json" {
  value = local.person_json
}

output "person_back" {
  value = local.person_back
}

output "person_name" {
  value = local.person_back.Name
}
```

`person_name` shows that the decoded value is a real object whose attributes can
be accessed again.

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

No infrastructure is created; only the outputs are recorded in state:

```text
Outputs:

person_back = {
  "Age" = 55
  "Name" = "Blas"
}
person_json = "{\"Age\":55,\"Name\":\"Blas\"}"
person_name = "Blas"
```

### 3. Experiment in the console (optional)

```bash
terraform console
```

```text
> local.person_json
> jsondecode(local.person_json).Age
> jsonencode(["a", "b"])
```

## Key Takeaways

- `jsonencode(value)` converts any Terraform value to a JSON **string**.
- `jsondecode(string)` parses a JSON string into a Terraform value.
- `jsondecode(jsonencode(x)) == x`; the two functions are inverses.
- Encode HCL maps and objects, not heredocs: a heredoc is always a plain string,
  so `jsonencode()` would only produce a quoted, escaped string literal.
- `jsonencode()` is commonly used for IAM policies, container definitions, and
  other arguments that expect a JSON document.
