# Terraform Automation — `TF_IN_AUTOMATION`

A small practice project used to explore the behaviour of the `TF_IN_AUTOMATION`
environment variable when running Terraform.

## Contents

- `main.tf` — a minimal configuration that declares a single AWS security group.

```hcl
resource "aws_security_group" "sg" {
  name = "test-sg"
}
```

## What is `TF_IN_AUTOMATION`?

`TF_IN_AUTOMATION` is a special environment variable recognized by Terraform.
When it is set to **any non-empty value**, Terraform assumes it is running
inside an automated pipeline (CI/CD) rather than in an interactive terminal.

Its only effect is to make Terraform's output **friendlier for automation**:

- It **suppresses hints and suggestions** that direct you to run follow-up CLI
  commands. For example, after `terraform plan` Terraform normally reminds you
  to run `terraform apply`; with `TF_IN_AUTOMATION` set, that suggestion is
  omitted (since in a pipeline the next step is scripted, not manual).
- It does **not** change any actual behaviour of plan, apply, or destroy, and it
  does **not** disable interactive prompts. To skip approval prompts you still
  need flags such as `-auto-approve` or `-input=false`.

The value itself is irrelevant — Terraform only checks whether the variable is
set and non-empty. Common conventions are `TF_IN_AUTOMATION=true` or
`TF_IN_AUTOMATION=1`.

## Usage

### Set it for a single command

```bash
TF_IN_AUTOMATION=true terraform plan
```

### Export it for the whole session

```bash
export TF_IN_AUTOMATION=true

terraform init
terraform plan
terraform apply
```

### Typical non-interactive automation flow

```bash
export TF_IN_AUTOMATION=true

terraform init -input=false
terraform plan -input=false -out=tfplan
terraform apply -input=false tfplan
```

## Observing the difference

1. Run a plan **without** the variable and note the "run `terraform apply`" hint
   at the end of the output:

   ```bash
   unset TF_IN_AUTOMATION
   terraform plan
   ```

2. Run the same plan **with** the variable set and observe that the follow-up
   command hints are gone:

   ```bash
   TF_IN_AUTOMATION=true terraform plan
   ```

## Notes

- This example references an `aws_security_group`, so it requires the AWS
  provider and valid AWS credentials to actually apply.
- `TF_IN_AUTOMATION` is purely cosmetic/UX-oriented; combine it with
  `-input=false` and `-auto-approve` for a fully non-interactive pipeline.

## References

- Terraform docs: [Running Terraform in Automation](https://developer.hashicorp.com/terraform/tutorials/automation/automate-terraform)
