# Input Variable Validation in Terraform

This example demonstrates how to use
[custom validation rules](https://developer.hashicorp.com/terraform/language/values/variables#custom-validation-rules)
to check the values of input variables **before** Terraform plans or changes
anything.

The scenario: four input variables (a database password, an EC2 instance type,
an email address, and an AMI ID) each have a `validation` block. If a value
breaks a rule, Terraform stops with a clear error message instead of failing
later inside a provider or in the cloud.

No providers or resources are used; only the variables are checked.

## Files

| File           | Purpose                                                    |
| -------------- | ---------------------------------------------------------- |
| `variables.tf` | Declares four input variables, each with a validation rule. |

## How a Validation Block Works

```hcl
variable "example" {
  type = string

  validation {
    condition     = <expression that returns true or false>
    error_message = "Message shown when the condition is false."
  }
}
```

- **`condition`**: must return `true` for a valid value. If it returns `false`,
  Terraform shows `error_message` and stops.
- **`error_message`**: the text the user sees. Explain what a valid value looks
  like.
- A variable can have **several** `validation` blocks. All of them must pass.
- Validation runs during `plan` and `apply`, as soon as the variable values are
  known and before any provider is called.

## The Configuration

### `db_password`: minimum length with `length()`

```hcl
variable "db_password" {
  type        = string
  description = "Password for the database"
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 12
    error_message = "Password must be at least 12 characters long"
  }
}
```

`length()` returns the number of characters in a string. Passwords shorter than
12 characters are rejected.

`sensitive = true` hides the value in plan output and in error messages. When
the check fails, the error does not show the password.

### `instance_type`: allowed list with `contains()`

```hcl
variable "instance_type" {
  type        = string
  description = "EC2 instance type"

  validation {
    condition     = contains(["t2.micro", "t2.medium", "t2.large"], var.instance_type)
    error_message = "Instance type must be: t2.micro, t2.medium or t2.large"
  }
}
```

`contains(list, value)` returns `true` if the value is in the list. Only the
three listed instance types are allowed.

### `email_id`: pattern matching with `can()` and `regex()`

```hcl
variable "email_id" {
  type        = string
  description = "Email"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.email_id))
    error_message = "Invalid email address"
  }
}
```

- `regex(pattern, string)` returns the match, but **raises an error** if there
  is no match.
- `can(expression)` turns that error into `false` (and a success into `true`),
  so the result can be used as a condition.
- The pattern has three parts:

  | Part                    | Matches                                            |
  | ----------------------- | -------------------------------------------------- |
  | `^[a-zA-Z0-9._%+-]+`    | The name before `@` (letters, digits, `._%+-`)     |
  | `@[a-zA-Z0-9.-]+`       | `@` and the domain (letters, digits, `.`, `-`)     |
  | `\\.[a-zA-Z]{2,}$`      | A dot and a top-level domain of 2+ letters         |

- The backslash is doubled (`\\.`) because `\` is an escape character in
  Terraform strings. `\.` means a literal dot in the regular expression.
- This accepts `blas@example.com` and `first.last+tag@mail.example.co.uk`, and
  rejects `foo`, `a b@x.com` (contains a space) and `a@b.c` (top-level domain
  only one letter).

### `ami_id`: prefix check with `substr()`

```hcl
variable "ami_id" {
  type        = string
  description = "AMI ID"

  validation {
    condition     = length(var.ami_id) > 4 && substr(var.ami_id, 0, 4) == "ami-"
    error_message = "The AMI ID must be longer than 4 characters and start with ami-"
  }
}
```

- `substr(string, offset, length)` returns the first 4 characters, which must be
  `ami-`.
- `length(var.ami_id) > 4` makes sure something comes after the prefix, so
  `ami-` on its own is rejected.
- `&&` means both conditions must be `true`.

### Summary of the rules

| Variable        | Function(s)        | Valid example          | Invalid example |
| --------------- | ------------------ | ---------------------- | --------------- |
| `db_password`   | `length()`         | `supersecret123`       | `short`         |
| `instance_type` | `contains()`       | `t2.micro`             | `t3.micro`      |
| `email_id`      | `can()`, `regex()` | `blas@example.com`     | `a@b.c`         |
| `ami_id`        | `length()`, `substr()` | `ami-0123456789abcdef0` | `ami-`     |

## Prerequisites

- Terraform installed

No providers, network access, or cloud credentials are required.

## Step-by-Step Process

### 1. Initialize the working directory

```bash
terraform init
```

### 2. Try invalid values

```bash
terraform plan \
  -var db_password=short \
  -var instance_type=t3.micro \
  -var email_id=a@b.c \
  -var ami_id=ami-
```

Terraform checks every variable and reports all failures at once, for example:

```text
Error: Invalid value for variable

  on variables.tf line 12:
  12: variable "instance_type" {
    ├────────────────
    │ var.instance_type is "t3.micro"

Instance type must be: t2.micro, t2.medium or t2.large

This was checked by the validation rule at variables.tf:16,3-13.
```

The error for `db_password` does not show the value, because the variable is
marked as sensitive:

```text
Error: Invalid value for variable

  on variables.tf line 1:
   1: variable "db_password" {

Password must be at least 12 characters long

This was checked by the validation rule at variables.tf:6,3-13.
```

### 3. Try valid values

```bash
terraform plan \
  -var db_password=supersecret123 \
  -var instance_type=t2.micro \
  -var email_id=blas@example.com \
  -var ami_id=ami-0123456789abcdef0
```

All rules pass. Because there are no resources, Terraform reports:

```text
No changes. Your infrastructure matches the configuration.
```

If you run `terraform plan` without `-var` options, Terraform asks for each
value interactively, and the same rules are checked.

## Notes

- **`sensitive` is not encryption.** It only hides the value in CLI output. If a
  sensitive value is used by a resource, it is still stored in plain text in the
  state file.
- **The email pattern is practical, not perfect.** It catches common mistakes,
  but no simple regular expression matches every valid email address.

## Key Takeaways

- Use `validation` blocks to reject bad input early, with a helpful message.
- `condition` must return `true` or `false`; `error_message` explains the rule.
- Common functions for conditions: `length()`, `contains()`, `substr()`,
  `regex()`, and `startswith()`.
- Wrap functions that can fail, such as `regex()`, in `can()` to get `true` or
  `false` instead of an error.
- Combine checks with `&&` and `||`, or add several `validation` blocks to one
  variable.
- Mark secret variables as `sensitive = true`.
