# Copyright 2021 Teak.io, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

output "create_log_group" {
  description = "Set to true to have this module manage a log group for the Lambda function."
  value       = var.create_log_group
}

output "log_retention_in_days" {
  description = "The number of days to retain Lambda logs for."
  value       = var.log_retention_in_days
}

output "lambda_iam_role_arn" {
  description = "The ARN of an IAM role assigned to the created lambda."
  value       = local.iam_role_arn
}

output "lambda_name" {
  description = "The name of the lambda created by this module."
  value       = aws_lambda_function.cleanomat.function_name
}

output "ami_retain_count" {
  description = "The number of most recent AMIs to retain for each build type."
  value       = var.ami_retain_count
}

output "ami_retain_days" {
  description = "Minimum age of an AMI in days to be eligible for cleanup."
  value       = var.ami_retain_days
}

output "tags" {
  description = "Tags to applied to all resources. Will be deduplicated from default tags."
  value       = local.tags
}

output "run_minute" {
  description = "Minute on the hour the AMI cleanomat runs."
  value       = var.run_minute
}

output "run_hour" {
  description = "UTC hour of the day the AMI cleanomat runs."
  value       = var.run_hour
}

output "run_days_of_the_week" {
  description = "Days of the week the AMI cleanomat runs. Uses three letter all caps abbreviations, e.g. TUE-THU"
  value       = var.run_days_of_the_week
}
