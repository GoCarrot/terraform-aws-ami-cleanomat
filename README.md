# AMI Cleanomat

The AMI Cleanomat cleans up old AMIs and snapshots created by Teak's immutable infrastructure build process. The AMI cleanomat assumes an AMI naming scheme of `<ami_group_id>.<timestamp>`.

## Installation

This is a complete example of a minimal AMI cleanomat setup.

```hcl
module "cleanomat" {
  source = "GoCarrot/ami-cleanomat/aws"
}
```

By default the AMI cleanomat will run at 18:00 UTC Monday through Friday. This default was selected to ensure that changes made by the AMI cleanomat happen during regular business hours on the continental US.

To change when the AMI cleanomat runs use the `run_minute`, `run_hour`, and `run_days_of_the_week` variables. For example, here is an AMI cleanomat which will run during normal business hours in Israel.

```hcl
module "cleanomat" {
  source = "GoCarrot/ami-cleanomat/aws"

  run_hour             = 8
  run_days_of_the_week = "SUN-THU"
}
```

By default the AMI Cleanomat will retain the intersection of the five most recently created AMIs and all AMIs created in the past seven days per ami_group_id. These values can be controlled using the `ami_retain_count` and `ami_retain_days` variables. For example, to retain _only_ AMIs created in the past week,

```hcl
module "cleanomat" {
  source = "GoCarrot/ami-cleanomat/aws"

  ami_retain_count = 0
  ami_retain_days  = 7
}
```

I recommend setting both `ami_retain_count` and `ami_retain_days` to positive values, especially in production, such that you do not deregister AMIs that are still in use for infrequently updated services and to ensure that you retain source AMIs and EBS snapshots for a duration as may be required by your auditing and compliance needs.

### Multi-Account Setups

If you are using Teak's multi-account setup with separate CI/CD accounts for performing AMI builds and workload accounts for running services using buitl AMIs, the AMI Cleanomat should be deployed in each CI/CD account.
