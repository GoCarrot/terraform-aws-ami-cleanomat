## 0.0.5

ENHANCEMENTS:

* Support log group encryption by setting kms_key_arn variable (#1)
* Support X-Ray tracing of Lambda (#1)

SPECIAL THANKS

* @MrJoy

## 0.0.4

BUG FIXES:

* Don't crash when we encounter an AMI that doesn't match our expected naming scheme.

## 0.0.3

BUG FIXES:

* Resolve terraform error when specifying lambda_iam_role_arn.

## 0.0.2

ENHANCEMENTS:

* Tag all log messages with the name of the AMI involved
* Remove region constraints from created IAM policies

## 0.0.1

Initial Release
