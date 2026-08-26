# Terraform Provider Plugin Caching

This example demonstrates how Terraform can reuse provider packages from a local plugin cache instead of downloading them again for every working directory.

## Configuration

Terraform CLI settings belong in a file named `.terraformrc` in the current user's home directory:

```hcl
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
plugin_cache_may_break_dependency_lock_file = true
```
Terraform automatically looks for this file in the home directory. You can use a different CLI configuration file by setting `TF_CLI_CONFIG_FILE`.

Create the cache directory before initializing a project:

```shell
mkdir -p "$HOME/.terraform.d/plugin-cache"
```

The Terraform configuration in this example uses the AWS provider:

```hcl
provider "aws" {
}

resource "aws_security_group" "sg" {
  name = "test-sg"
}
```

## Initialize with the Cache

From this directory, initialize Terraform:

```shell
terraform init
```

Terraform checks the configured cache for a matching provider version. If the provider is already cached, Terraform can install it from the cache. If it is not cached, Terraform downloads it and stores a copy in the cache for later use.

To confirm the active CLI configuration, use:

```shell
terraform version
```

The initialization output identifies the selected provider version and whether it was loaded from the shared cache or downloaded.

## Dependency Lock File Warning

Terraform normally records provider checksums in `.terraform.lock.hcl`. When
`plugin_cache_may_break_dependency_lock_file = true` is enabled, Terraform may
install a provider from the cache without having complete checksums for every
platform. Initialization can therefore show a warning like:

```text
Warning: Incomplete lock file information for providers
```

This setting can be useful for a local demonstration, but it weakens the
portability guarantees of the lock file. Keep `.terraform.lock.hcl` under version
control and generate checksums for every platform that the project supports.
For example:

```shell
terraform providers lock \
  -platform=linux_amd64 \
  -platform=darwin_arm64 \
  -platform=windows_amd64
```

Adjust the platforms to match the machines used by the team or CI system.
