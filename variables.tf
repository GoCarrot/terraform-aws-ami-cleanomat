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

variable "create_log_group" {
  type        = bool
  description = "Set to true to have this module manage a log group for the Lambda function."
  default     = true
}

variable "log_retention_in_days" {
  type        = number
  description = "The number of days to retain Lambda logs for."
  default     = 90
}

variable "lambda_iam_role_arn" {
  type        = string
  description = "The ARN of an IAM role to assign to the created lambda. If null, this module will create a suitable IAM role and policy."
  default     = null
}

variable "lambda_name" {
  type        = string
  description = "The name of the lambda created by this module."
  default     = "AmiCleanomat"
}

variable "ami_retain_count" {
  type        = number
  description = "The number of most recent AMIs to retain for each build type."
  default     = 5
}

variable "ami_retain_days" {
  type        = number
  description = "Minimum age of an AMI in days to be eligible for cleanup."
  default     = 7
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources. Will be deduplicated from default tags."
  default     = {}
}

variable "run_minute" {
  type        = number
  description = "Minute on the hour to run the AMI cleanomat"
  default     = 0
}

variable "run_hour" {
  type        = number
  description = "UTC hour of the day to run the AMI cleanomat."
  # Chosen for continental US business hours.
  default = 18
}

variable "run_days_of_the_week" {
  type        = string
  description = "Days of the week to run the AMI cleanomat. Uses three letter all caps abbreviations, e.g. TUE-THU"
  default     = "MON-FRI"
}
