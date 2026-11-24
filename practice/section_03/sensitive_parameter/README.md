# Sensitive Values in Terraform

This example demonstrates how Terraform hides secret values from its output,
using:

- a **sensitive input variable** (`sensitive = true` in a `variable` block),
- **sensitive outputs** (`sensitive = true` in an `output` block), and
- the **`local_sensitive_file`** resource, whose content is always sensitive.

The scenario: a password is passed in as a variable and written to a file, and
a second secret is written with `local_sensitive_file`. Both files' contents
are exposed as outputs, and Terraform hides them as `(sensitive value)` and
`<sensitive>`.

## Files

| File                  | Purpose                                                              |
| --------------------- | -------------------------------------------------------------------- |
| `variables.tf`        | Declares the sensitive `password` variable.                          |
| `main.tf`             | Defines a `local_file`, a `local_sensitive_file`, and two sensitive outputs. |
| `.terraform.lock.hcl` | Dependency lock file created by `terraform init` (`hashicorp/local` `2.9.1`). |
| `demo.txt`            | Created by `local_file.file` after `apply` (contains the password).  |
| `secret_file.txt`     | Created by `local_sensitive_file.file` after `apply`.               |

## The Configuration

### `variables.tf`: a sensitive input variable

```hcl
variable "password" {
  type        = string
  description = "User's password"
  sensitive   = true
}
```

`sensitive = true` tells Terraform to hide this value wherever it is shown in
the CLI. Any value **derived** from it (such as `local_file.file.content`) is
also treated as sensitive.

### `main.tf`

```hcl
resource "local_file" "file" {
  filename = "demo.txt"
  content  = var.password
}

output "file_content" {
  value     = local_file.file.content
  sensitive = true
}

resource "local_sensitive_file" "file" {
  filename = "secret_file.txt"
  content  = "Passw0rd!!"
}

output "sensitive_file_content" {
  value     = local_sensitive_file.file.content
  sensitive = true
}
```

- **`local_file.file`**: a normal resource. Its `content` is hidden only because
  it comes from the sensitive variable.
- **`local_sensitive_file.file`**: works like `local_file`, but its `content`
  is marked sensitive by the provider itself, so it is hidden even when it is a
  plain string. It also creates the file with stricter default permissions
  (`0700` instead of `0777`).
- **Outputs**: both outputs refer to sensitive values, so they **must** have
  `sensitive = true` (see [step 5](#5-see-what-happens-without-sensitive--true-on-an-output)).

## Ways to Mark a Value as Sensitive

| Method                          | Example                                  |
| ------------------------------- | ---------------------------------------- |
| Input variable                  | `variable "x" { sensitive = true }`      |
| Output value                    | `output "x" { sensitive = true }`        |
| Provider schema                 | `local_sensitive_file.content`, `aws_db_instance.password` |
| `sensitive()` function          | `content = sensitive("Passw0rd!!")`      |
| Derived from a sensitive value  | `"${var.password}-suffix"` is also sensitive |

`nonsensitive(value)` removes the mark again. Use it only when you are sure the
value is safe to show.

## Prerequisites

- Terraform installed
- Network access to the Terraform Registry (for `terraform init`)

No cloud credentials are required. The `local` provider only writes files on the
machine running Terraform.

## Step-by-Step Process

### 1. Initialize the working directory

```bash
terraform init
```

### 2. Apply the configuration

```bash
terraform apply -var password=MySecret123
```

Without `-var`, Terraform asks for the password. The secret values are hidden in
the plan and in the outputs:

```text
  # local_file.file will be created
  + resource "local_file" "file" {
      + content              = (sensitive value)
      ...
      + file_permission      = "0777"
      + filename             = "demo.txt"
    }

  # local_sensitive_file.file will be created
  + resource "local_sensitive_file" "file" {
      + content              = (sensitive value)
      ...
      + file_permission      = "0700"
      + filename             = "secret_file.txt"
    }

Changes to Outputs:
  + file_content           = (sensitive value)
  + sensitive_file_content = (sensitive value)
...
Outputs:

file_content = <sensitive>
sensitive_file_content = <sensitive>
```

### 3. Read the sensitive outputs

`terraform output` hides them too:

```bash
terraform output
# file_content = <sensitive>
# sensitive_file_content = <sensitive>
```

But you can still read them on purpose:

```bash
terraform output -raw file_content
# MySecret123

terraform output -json
# {
#   "file_content": { "sensitive": true, "type": "string", "value": "MySecret123" },
#   "sensitive_file_content": { "sensitive": true, "type": "string", "value": "Passw0rd!!" }
# }
```

### 4. Look at the files and the state

```bash
ls -l demo.txt secret_file.txt
# -rwxr-xr-x ... demo.txt          (0777, reduced by the umask)
# -rwx------ ... secret_file.txt   (0700, only the owner can read it)

grep -n 'MySecret123\|Passw0rd' terraform.tfstate
```

Both secrets are stored in **plain text** in `terraform.tfstate`, both in the
outputs and in the resource attributes.

### 5. See what happens without `sensitive = true` on an output

Remove `sensitive = true` from the `file_content` output and run
`terraform plan`:

```text
Error: Output refers to sensitive values

  on main.tf line 6:
   6: output "file_content" {

To reduce the risk of accidentally exporting sensitive data that was intended
to be only internal, Terraform requires that any root module output
containing sensitive data be explicitly marked as sensitive, to confirm your
intent.
```

Add `sensitive = true` back afterwards.

### 6. Clean up

```bash
terraform destroy -var password=MySecret123
```

This deletes `demo.txt` and `secret_file.txt`.

## Notes

- **`sensitive` is not encryption.** It only hides values in CLI output. Secrets
  are still saved in plain text in the state file, in `terraform output -json`,
  and in the files written to disk. Protect the state (for example, a remote
  backend with encryption and access control), and do not commit it to Git.
- **A secret is hard-coded in `main.tf`.** `"Passw0rd!!"` is visible to anyone
  who can read the code. In real projects, pass secrets in through variables,
  environment variables (`TF_VAR_password`), or a secrets manager.
- **`demo.txt` is readable by other users.** `local_file` uses permissions
  `0777` by default. Set `file_permission = "0600"`, or use
  `local_sensitive_file`, when writing secrets.
- **Formatting.** `variables.tf` uses 4-space indentation and unaligned `=`
  signs; `terraform fmt` will fix it.

## Key Takeaways

- `sensitive = true` on a variable hides its value and every value derived from
  it in plans, applies and outputs.
- A root module output that contains a sensitive value must be marked
  `sensitive = true`, or Terraform stops with an error.
- Some resource attributes are sensitive by design, such as
  `local_sensitive_file.content`.
- Sensitive outputs can still be read with `terraform output -raw` or
  `terraform output -json`.
- Sensitive values are still stored in plain text in the state file, so the
  state must be protected.
