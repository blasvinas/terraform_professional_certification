# Terraform Provider Mirror

This example demonstrates how to create a local filesystem mirror for Terraform providers with `terraform providers mirror`.

## Configuration

`main.tf` declares two providers:

```hcl
provider "aws" {
}

provider "azurerm" {
}
```

Terraform uses the provider requirements discovered from the configuration and the dependency lock file to determine which provider packages to mirror.

## Create the Mirror

Create the destination directory, then run the mirror command from this directory:

```shell
mkdir -p "$HOME/tf-mirror"
terraform providers mirror "$HOME/tf-mirror"
```

The command downloads the required provider packages into the destination using Terraform's filesystem mirror layout. For this example, the mirror contains packages for both `hashicorp/aws` and `hashicorp/azurerm`, for example:

```text
~/tf-mirror/
├── registry.terraform.io/
│   └── hashicorp/
│       ├── aws/
│       └── azurerm/
```

The exact version and platform directories depend on the selected provider versions and the platform used to run the command.

## Configure Terraform to Use the Mirror

Tell Terraform to search the mirror during provider installation by adding a `provider_installation` block to the user CLI configuration file, normally `~/.terraformrc`:

```hcl
provider_installation {
  filesystem_mirror {
    path    = "/home/your-user/tf-mirror"
    include = ["registry.terraform.io/*/*"]
  }

  direct {
    include = ["registry.terraform.io/*/*"]
  }
}
```

Replace `/home/your-user/tf-mirror` with the absolute path to the mirror. The `filesystem_mirror` block makes the local directory available to Terraform. The `direct` block uses `include`, so the matching providers are also eligible to be downloaded directly from the public registry if needed. Because both methods include the same provider addresses, Terraform may use either the mirror or the registry.

To require the mirrored providers and prevent Terraform from downloading them directly, use `exclude` on the `direct` method instead:

```hcl
direct {
  exclude = ["registry.terraform.io/*/*"]
}
```

Then initialize the example:

```shell
terraform init
```

Terraform should install the providers from the configured mirror. Run `terraform init -upgrade` after updating the mirror or changing provider version constraints.

## Verify the Installation

Inspect the providers required by the configuration:

```shell
terraform providers
```

You can also run initialization with detailed logging:

```shell
TF_LOG=INFO terraform init
```

The initialization output shows the provider installation process and can help confirm that the filesystem mirror is being used.

## Mirror Versus Plugin Cache

A provider mirror is an explicit directory of provider packages that Terraform can use as an installation source. It is useful for repeatable or restricted environments, including systems with limited network access.

A plugin cache is a shared cache that Terraform fills as providers are installed. Configure it with `plugin_cache_dir` in the CLI configuration. The two mechanisms can be used together, but they serve different purposes: the mirror is an installation source, while the cache avoids repeated copies after installation.

## Important Notes

- Run `terraform providers mirror` after changing provider requirements or the lock file so the mirror includes the needed versions.
- Keep `.terraform.lock.hcl` under version control to preserve provider selections and checksums.
- A mirror created on one platform may not contain packages for another platform. Mirror each required platform when preparing a shared mirror.
- Do not commit the local mirror directory to this project unless the repository is intentionally designed to store provider binaries.
- The mirror command populates provider packages; it does not configure Terraform to use the mirror. The `provider_installation` CLI configuration is required for `terraform init` to select it.
