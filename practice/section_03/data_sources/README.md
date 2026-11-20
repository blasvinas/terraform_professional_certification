# Data Sources in Terraform

This example demonstrates how to use a
[data source](https://developer.hashicorp.com/terraform/language/data-sources)
to **read** information that already exists outside of Terraform, and then use
that information when creating a resource.

The scenario: we want to launch an EC2 instance running the latest Red Hat
Enterprise Linux 10.2 image. AMI IDs are different in every region and change
whenever a new image is published, so instead of hard-coding an ID, the
`aws_ami` data source looks up the most recent matching AMI at plan time.

## Files

| File                  | Purpose                                                          |
| --------------------- | ---------------------------------------------------------------- |
| `versions.tf`         | Pins the AWS provider (`hashicorp/aws` `6.73.0`).                |
| `providers.tf`        | Configures the AWS provider for the `us-east-1` region.          |
| `main.tf`             | Defines the `aws_ami` data source and the `aws_instance` resource. |
| `.terraform.lock.hcl` | Dependency lock file created by `terraform init`.                |

## The Configuration

### The data source: `data "aws_ami" "rhel10"`

```hcl
data "aws_ami" "rhel10" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["RHEL-10.2.0_HVM-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
```

- **`data`** instead of `resource`: Terraform only reads this object. It never
  creates, changes, or destroys it.
- **`owners`**: only images from this owner are searched. Always set it, so you
  do not pick up a look-alike image published by someone else.
- **`filter`** blocks: each one maps to an
  [EC2 `DescribeImages` filter](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeImages.html).
  An image must match **all** filters. `*` is a wildcard.
- **`architecture` filter**: the name pattern `RHEL-10.2.0_HVM-*` matches both
  `x86_64` and `arm64` images. Restricting it to `x86_64` makes sure the image
  always boots on `t3.micro`, which is an x86 instance type.
- **`most_recent = true`**: when several images match, use the newest one.
  Without it, Terraform returns an error if more than one image matches.

When this was run, the lookup returned:

| Attribute      | Value                                           |
| -------------- | ----------------------------------------------- |
| `image_id`     | `ami-01126d0bab29817a7`                         |
| `name`         | `RHEL-10.2.0_HVM-20261020-x86_64-0-Hourly2-GP3` |
| `architecture` | `x86_64`                                        |
| `owner_id`     | `309956199498` (Red Hat)                        |

### The resource: `resource "aws_instance" "rhel10"`

```hcl
resource "aws_instance" "rhel10" {
  ami           = data.aws_ami.rhel10.image_id
  instance_type = "t3.micro"

  lifecycle {
    ignore_changes = [ami]
  }
}
```

A data source is referenced with the `data.` prefix:
`data.<TYPE>.<NAME>.<ATTRIBUTE>`. Here, `image_id` from the lookup becomes the
`ami` of the instance. The reference also creates an implicit dependency, so
Terraform always reads the data source before it creates the instance.

The `lifecycle { ignore_changes = [ami] }` block stops Terraform from replacing
the instance when a newer RHEL image is published. The data source is read again
on every plan, so without this block a new `image_id` would force a replacement.
The new AMI is only used when the instance is created again (for example with
`terraform apply -replace=aws_instance.rhel10`).

## Data Sources vs. Resources

|                         | `resource`                     | `data`                              |
| ----------------------- | ------------------------------ | ----------------------------------- |
| Purpose                 | Create and manage an object    | Read an existing object             |
| Reference syntax        | `aws_instance.rhel10.id`       | `data.aws_ami.rhel10.image_id`      |
| Stored in state         | Yes (`"mode": "managed"`)      | Yes (`"mode": "data"`)              |
| Affected by `destroy`   | Deleted                        | Only removed from state             |
| When it is evaluated    | During `apply`                 | During `plan` (or `apply` if inputs are unknown) |

## Prerequisites

- Terraform installed
- An AWS account with credentials configured (for example `aws configure`, or
  the `AWS_PROFILE` / `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` environment
  variables)
- Permissions for `ec2:DescribeImages` and `ec2:RunInstances`, and a default VPC
  in `us-east-1` (no subnet is set, so AWS uses the default VPC)

> **Cost:** this example launches a real EC2 instance. `t3.micro` is cheap (and
> may be free-tier eligible), but RHEL images include a license fee. Destroy the
> instance when you are done.

## Step-by-Step Process

### 1. Initialize the working directory

```bash
terraform init
```

### 2. Preview the plan

```bash
terraform plan
```

The data source is read during the plan, so the actual AMI ID already appears in
the planned `aws_instance`:

```text
data.aws_ami.rhel10: Reading...
data.aws_ami.rhel10: Read complete after 1s [id=ami-01126d0bab29817a7]
...
  + resource "aws_instance" "rhel10" {
      + ami           = "ami-01126d0bab29817a7"
      + instance_type = "t3.micro"
```

### 3. Apply the configuration

```bash
terraform apply
```

### 4. Inspect the data source (optional)

```bash
terraform state show data.aws_ami.rhel10
terraform console
```

```text
> data.aws_ami.rhel10.name
> data.aws_ami.rhel10.architecture
> data.aws_ami.rhel10.creation_date
```

### 5. Clean up

```bash
terraform destroy
```

This terminates the instance. The AMI is not touched; only its entry is removed
from the state.

## Notes

- **Updating to a newer AMI.** Because of `ignore_changes = [ami]`, a running
  instance keeps its original image. To move it to the latest image on purpose:

  ```bash
  terraform apply -replace=aws_instance.rhel10
  ```

- **Checking which image would be used now:**

  ```bash
  terraform console
  > data.aws_ami.rhel10.name
  ```

## Key Takeaways

- Data sources read existing information; they never create or modify anything.
- Reference them with `data.<TYPE>.<NAME>.<ATTRIBUTE>`.
- Using a data source for an AMI avoids hard-coded, region-specific IDs.
- Use `owners`, `filter`, and `most_recent` together to get exactly one
  trustworthy image. Filter on `architecture` so the image fits the instance
  type.
- Use `ignore_changes = [ami]` so a newly published image does not replace
  running instances.
- Referencing a data source from a resource creates an implicit dependency.
