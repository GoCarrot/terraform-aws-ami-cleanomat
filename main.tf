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

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.74.1, < 5"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2"
    }
  }
}

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_default_tags" "tags" {}

locals {
  lambda_name  = var.lambda_name
  logs_arn     = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:log-group:/aws/lambda/${local.lambda_name}"
  iam_role_arn = coalesce(var.lambda_iam_role_arn, try(aws_iam_role.cleanomat[0].arn))
  our_tags     = var.tags
  tags         = { for key, value in local.our_tags : key => value if lookup(data.aws_default_tags.tags.tags, key, null) != value }
}

data "aws_iam_policy_document" "allow-lambda-assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

data "aws_iam_policy_document" "cleanomat" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups"
    ]

    resources = [
      local.logs_arn,
      "${local.logs_arn}:log-stream:*"
    ]
  }

  statement {
    actions = [
      "ec2:DescribeImages"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:DeregisterImage",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}::image/*"
    ]

    # TODO: Condition on tags keys to only delete AMIs created by our build process.
  }

  statement {
    actions = [
      "ec2:DeleteSnapshot"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}::snapshot/*"
    ]

    # TODO: Condition on tag keys to only delete snapshots created by our build process.
  }
}

resource "aws_iam_role" "cleanomat" {
  count = var.lambda_iam_role_arn == null ? 1 : 0

  name               = local.lambda_name
  assume_role_policy = data.aws_iam_policy_document.allow-lambda-assume.json

  description = "Role for the ${local.lambda_name} Lambda."

  tags = local.tags
}

resource "aws_iam_policy" "cleanomat" {
  count = var.lambda_iam_role_arn == null ? 1 : 0

  name   = "${local.lambda_name}Cleanomat"
  policy = data.aws_iam_policy_document.cleanomat.json

  description = "Allows logging to ${local.lambda_name} lambda log groups and management of AMIs and snapshots as needed."

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "cleanomat" {
  count = var.lambda_iam_role_arn == null ? 1 : 0

  role       = aws_iam_role.cleanomat[count.index].name
  policy_arn = aws_iam_policy.cleanomat[count.index].arn
}

resource "aws_cloudwatch_log_group" "lambda" {
  count = var.create_log_group ? 1 : 0

  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = var.log_retention_in_days

  tags = local.tags
}

data "archive_file" "cleanomat" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/cleanomat.zip"
}

resource "aws_lambda_function" "cleanomat" {
  function_name    = local.lambda_name
  role             = local.iam_role_arn
  architectures    = ["arm64"]
  memory_size      = 512
  runtime          = "ruby2.7"
  filename         = data.archive_file.cleanomat.output_path
  source_code_hash = filebase64sha256(data.archive_file.cleanomat.output_path)
  handler          = "lambda_handlers.LambdaFunctions::Handler.cleanomat"
  publish          = true

  timeout = 900

  environment {
    variables = {
      AMI_RETAIN_COUNT = var.ami_retain_count
      AMI_RETAIN_DAYS  = var.ami_retain_days
    }
  }

  tags = local.tags

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.cleanomat
  ]
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name        = "${local.lambda_name}-run-schedule"
  description = "Runs ${local.lambda_name} like a cron job."

  schedule_expression = "cron(${var.run_minute} ${var.run_hour} ? * ${var.run_days_of_the_week} *)"

  tags = local.tags
}

resource "aws_lambda_permission" "cleanomat-schedule" {
  function_name = aws_lambda_function.cleanomat.function_name

  action     = "lambda:InvokeFunction"
  principal  = "events.${data.aws_partition.current.dns_suffix}"
  source_arn = aws_cloudwatch_event_rule.schedule.arn
}

resource "aws_cloudwatch_event_target" "cleanomat" {
  rule = aws_cloudwatch_event_rule.schedule.name
  arn  = aws_lambda_function.cleanomat.arn
}
