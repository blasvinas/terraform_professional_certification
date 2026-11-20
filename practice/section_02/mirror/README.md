# Terraform Provider Filesystem Mirror

This example demonstrates how to create a local filesystem mirror of provider
packages with `terraform providers mirror`, and how to configure Terraform to
install providers from it.

The scenario: you want to prepare provider packages ahead of time so that
`terraform init` can install them from a local directory, for example on a
machine with limited or no internet access.

## Files

| File      | Purpose                                                              |
| --------- | -------------------------------------------------------------------- |
| `main.tf` | Declares the `aws`, `azurerm`, and `google` providers to be mirrored. |

## The Configuration

```hcl
provider "aws" {
}

provider "azurerm" {
}

provider "google" {
}
```

Terraform uses the provider requirements discovered from the configuration (and
the dependency lock file, if present) to decide which provider packages to
mirror.

## Mirror Versus Plugin Cache

- **Filesystem mirror** — an explicit directory of provider packages that
  Terraform uses as an **installation source**. It is useful for repeatable or
  restricted environments.
- **Plugin cache** — a shared cache (`plugin_cache_dir`) that Terraform fills as
  providers are installed, to **avoid repeated downloads**. See the
  `plugin_caching` example.

The two mechanisms can be used together, but they serve different purposes.

## Prerequisites

- Terraform installed
- Network access to the Terraform Registry (to populate the mirror)

No cloud credentials are required. Provider blocks are only declared; nothing is
planned or applied.

## Step-by-Step Process

### 1. Create the mirror

```bash
mkdir -p "$HOME/tf-mirror"
terraform providers mirror "$HOME/tf-mirror"
```

Terraform downloads the required provider packages into the destination using
the filesystem mirror layout:

```text
~/tf-mirror/
└── registry.terraform.io/
    └── hashicorp/
        ├── aws/
        ├── azurerm/
        └── google/
```

The exact version and platform directories depend on the selected provider
versions and the platform used to run the command.

### 2. Configure Terraform to use the mirror

Add a `provider_installation` block to the CLI configuration file, normally
`~/.terraformrc`:

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

- **`filesystem_mirror`** — makes the local directory available as an
  installation source. Replace `path` with the absolute path to the mirror.
- **`direct`** — with `include`, the same providers can still be downloaded from
  the public registry, so Terraform may use either source.

To **require** the mirror and block direct downloads, use `exclude` instead:

```hcl
direct {
  exclude = ["registry.terraform.io/*/*"]
}
```

### 3. Initialize the working directory

```bash
terraform init
```

Terraform installs the providers from the configured mirror. Run
`terraform init -upgrade` after updating the mirror or changing provider version
constraints.

### 4. Verify the installation

```bash
terraform providers
TF_LOG=INFO terraform init
```

The detailed log shows the provider installation process and confirms whether
the filesystem mirror is being used.

## Key Takeaways

- `terraform providers mirror` only **populates** the mirror; the
  `provider_installation` CLI configuration is what makes `terraform init` use
  it.
- Re-run the mirror command after changing provider requirements or the lock
  file so the mirror includes the needed versions.
- A mirror created on one platform may not contain packages for another;
  mirror each required platform when preparing a shared mirror.
- Keep `.terraform.lock.hcl` under version control, but do not commit the mirror
  directory itself unless the repository is meant to store provider binaries.
