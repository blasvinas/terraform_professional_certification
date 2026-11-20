# Terraform Provider Plugin Caching

This example demonstrates how Terraform can reuse provider packages from a local
plugin cache instead of downloading them again for every working directory.

The scenario: several projects use the AWS provider. Without a cache, every
`terraform init` downloads the same large provider package again; with a cache,
it is downloaded once and reused.

## Files

| File          | Purpose                                     |
| ------------- | ------------------------------------------- |
| `provider.tf` | Declares the `aws` provider.                |
| `main.tf`     | Defines a single AWS security group.        |

## The Configuration

The cache is configured in the **CLI configuration file**, not in the project.
Terraform reads `~/.terraformrc` by default (or the file set in
`TF_CLI_CONFIG_FILE`):

```hcl
plugin_cache_dir                            = "$HOME/.terraform.d/plugin-cache"
plugin_cache_may_break_dependency_lock_file = true
```

- **`plugin_cache_dir`** — the shared directory where Terraform stores and looks
  up provider packages. It must already exist.
- **`plugin_cache_may_break_dependency_lock_file`** — allows Terraform to use a
  cached provider even when the lock file does not yet have checksums for it
  (see the warning below).

The project itself is a minimal AWS configuration:

```hcl
provider "aws" {
}

resource "aws_security_group" "sg" {
  name = "test-sg"
}
```

## Prerequisites

- Terraform installed
- Network access to the Terraform Registry (for the first download)

AWS credentials are only needed if you go on to plan or apply.

## Step-by-Step Process

### 1. Configure the CLI

Add the settings shown above to `~/.terraformrc`.

### 2. Create the cache directory

```bash
mkdir -p "$HOME/.terraform.d/plugin-cache"
```

### 3. Initialize the working directory

```bash
terraform init
```

If the provider is not cached yet, Terraform downloads it and stores a copy in
the cache. If it is already cached, Terraform installs it from the cache.

### 4. Verify the cache

```bash
ls -R "$HOME/.terraform.d/plugin-cache"
```

Running `terraform init` in another project that uses the same provider version
now reuses the cached package instead of downloading it again.

## Dependency Lock File Warning

With `plugin_cache_may_break_dependency_lock_file = true`, Terraform may install
a provider from the cache without complete checksums for every platform.
Initialization can then show:

```text
Warning: Incomplete lock file information for providers
```

To keep the lock file portable, generate checksums for every platform the
project supports:

```bash
terraform providers lock \
  -platform=linux_amd64 \
  -platform=darwin_arm64 \
  -platform=windows_amd64
```

Adjust the platforms to match the machines used by the team or CI system.

## Key Takeaways

- The plugin cache is configured in the CLI configuration file, not in `.tf`
  files.
- The cache directory must exist before Terraform can use it.
- Cached providers are reused across projects, saving download time and disk
  space.
- `plugin_cache_may_break_dependency_lock_file` is convenient but weakens lock
  file portability; use `terraform providers lock` to fill in checksums.
