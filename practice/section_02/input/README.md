# Required Variable Input

This example demonstrates how Terraform fails when a required input variable is not provided.

## Configuration

`main.tf` declares `file_name` without a default value:

```hcl
variable "file_name" {}
```

The variable is used as the destination filename for a `local_file` resource:

```hcl
resource "local_file" "foo" {
  content  = "Hello, World!"
  filename = var.file_name
}
```

Because `file_name` has no default, the root module requires a value before Terraform can create or plan the resource.

## Reproduce the Failure

Initialize the working directory, then run a plan with interactive input disabled:

```shell
terraform init
terraform plan -input=false
```

Terraform fails with an error similar to:

```text
Error: No value for required variable

The root module input variable "file_name" is not set, and has no default value.
Use a -var or -var-file command line argument to provide a value.
```

The `-input=false` option prevents Terraform from prompting for the missing value. This makes the command fail immediately when the required input is absent, which is useful in automation and CI/CD pipelines.

## Provide the Required Input

Pass the value directly on the command line:

```shell
terraform plan -input=false -var='file_name=hello.txt'
```

To create the file, provide the same variable to `apply`:

```shell
terraform apply -input=false -auto-approve -var='file_name=hello.txt'
```

The command creates `hello.txt` containing:

```text
Hello, World!
```

The value can also be supplied through a variable definition file. Create `terraform.tfvars` with:

```hcl
file_name = "hello.txt"
```

Then run:

```shell
terraform plan -input=false
terraform apply -input=false -auto-approve
```

## Cleanup

Remove the file created by Terraform and the local state:

```shell
terraform destroy -input=false -auto-approve -var='file_name=hello.txt'
```

Alternatively, delete the generated `hello.txt` and Terraform state files after experimenting.
