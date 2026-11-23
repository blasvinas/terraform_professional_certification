# Check Blocks in Terraform

This example demonstrates how to use a
[`check` block](https://developer.hashicorp.com/terraform/language/checks)
to validate your infrastructure **without blocking** Terraform operations.

The scenario: we want to make sure a website is up. A `check` block uses the
`hashicorp/http` provider to send a request to the site, and an `assert` checks
that the response has the HTTP status code `200` (OK). If the site is down,
Terraform shows a **warning**, but `plan` and `apply` still finish.

## Files

| File                  | Purpose                                                           |
| --------------------- | ----------------------------------------------------------------- |
| `main.tf`             | Defines the `website_check` check block with an `http` data source. |
| `.terraform.lock.hcl` | Dependency lock file created by `terraform init` (`hashicorp/http` `3.6.3`). |

There is no `versions.tf` or `providers.tf`. Terraform finds the `http`
provider automatically from the `data "http"` block, and the provider needs no
configuration.

## The Configuration

```hcl
check "website_check" {
  data "http" "website" {
    url = "https://www.google.com"
  }

  assert {
    condition     = data.http.website.status_code == 200
    error_message = "Website is down."
  }
}
```

### `check "website_check"`

A named block that groups the checks. It is not a resource; it does not create
anything.

### Scoped data source: `data "http" "website"`

- A `check` block can contain **one** nested data source.
- The `http` data source sends a `GET` request to `url` and returns the result,
  including `status_code`, `response_headers` and `response_body`.
- The `url` must include the scheme (`https://`).
- A nested data source is read **last**, after all other resources are planned
  or applied.
- If it fails (for example, the host does not exist), Terraform shows a
  **warning** instead of an error.

### `assert`

- `condition` must return `true` for the check to pass.
- `error_message` is shown as a **warning** when the condition is `false`.
- A check block can have several `assert` blocks.
- An `assert` can reference anything in the configuration (resources, data
  sources, variables), not only the nested data source.

## Check Blocks vs. Other Conditions

|                     | Variable `validation` | `precondition` / `postcondition` | `check` block                |
| ------------------- | --------------------- | -------------------------------- | ---------------------------- |
| Where               | `variable` block      | `lifecycle` of a resource, data source, or `output` | Top level of the module |
| When it fails       | **Error**: stops      | **Error**: stops                 | **Warning**: continues       |
| Tied to one object  | Yes (the variable)    | Yes (the resource)               | No                           |
| Typical purpose     | Reject bad input      | Check assumptions and guarantees | Check the overall health of the infrastructure |

## Prerequisites

- Terraform 1.5 or later (`check` blocks were added in 1.5)
- Network access to the Terraform Registry (for `terraform init`) and to the
  website being checked

No cloud credentials are required.

## Step-by-Step Process

### 1. Initialize the working directory

```bash
terraform init
```

### 2. Run a plan with a working website

```bash
terraform plan
```

The website is reached and returns `200`, so the check passes silently:

```text
data.http.website: Reading...
data.http.website: Read complete after 1s [id=https://www.google.com]
...
 <= data "http" "website" {
      ...
      + status_code          = 200
      + url                  = "https://www.google.com"
    }

Plan: 0 to add, 0 to change, 0 to destroy.
```

The data source is shown as `<= read` with the note
`(config will be reloaded to verify a check block)`. Data sources in check
blocks are always read again during `apply`, so the check reflects the
current state.

### 3. Make the assertion fail

Change `url` to a page that does not exist, for example
`https://www.google.com/this-page-does-not-exist`, and run `terraform plan`
again. The site returns `404`, so the assertion fails with a **warning**:

```text
Plan: 0 to add, 0 to change, 0 to destroy.

Warning: Check block assertion failed

  on main.tf line 7, in check "website_check":
   7:     condition     = data.http.website.status_code == 200
    ├────────────────
    │ data.http.website.status_code is 404

Website is down.
```

### 4. Make the data source fail

Change `url` to a host that does not exist, for example
`https://nonexistent.invalid`, and run `terraform apply`. The request fails,
but Terraform still shows only a warning and finishes successfully (exit
code `0`):

```text
Warning: Error making request

  with data.http.website,
  on main.tf line 2, in check "website_check":
   2:   data "http" "website" {

Error making request: GET https://nonexistent.invalid giving up after 1
attempt(s): Get "https://nonexistent.invalid": dial tcp: lookup
nonexistent.invalid on 192.168.1.254:53: no such host

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

Change `url` back to `https://www.google.com` afterwards.

### 5. View the check results (optional)

The result of the last run is saved in the `check_results` section of
`terraform.tfstate`, with a `status` of `pass`, `fail` or `unknown`:

```bash
jq '.check_results' terraform.tfstate
```

## Notes

- **The saved state is from an earlier test.** The current `terraform.tfstate`
  holds a failed check for `www.blasvinas.com`. That URL has no scheme, so the
  request failed with `unsupported protocol scheme ""`. Run `terraform apply`
  again to save the result for the current URL.
- **Check blocks never stop Terraform.** Because failures are only warnings,
  they are not suitable for checks that must block a deployment. Use a
  `precondition`, `postcondition` or variable `validation` for that.
- **The provider version is not pinned in the configuration.** Only the lock
  file pins `hashicorp/http` to `3.6.3`. Add a `versions.tf` with
  `required_providers` to pin it explicitly, as in the other examples.
- **HCP Terraform** can run check blocks regularly as part of
  [continuous validation](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/health#continuous-validation)
  and notify you when a check starts failing.

## Key Takeaways

- A `check` block validates infrastructure and reports failures as
  **warnings**, so `plan` and `apply` still finish.
- A check block can contain one scoped data source and one or more `assert`
  blocks.
- Errors in the scoped data source are also only warnings.
- Scoped data sources are read last and again during every `apply`, so checks
  show the current state.
- Use check blocks for monitoring-style checks (is the site up? is the
  certificate still valid?), and conditions or validations for rules that must
  block changes.
