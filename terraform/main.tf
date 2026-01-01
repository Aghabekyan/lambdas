# main.tf

provider "aws" {
  region  = "us-east-1"
  profile = "playground"   # name of your AWS CLI profile
}

resource "aws_iam_role" "lambda_role" {
  name = "playground-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}


# Create one SQS queue per country code
resource "aws_sqs_queue" "country_queues" {
  for_each = toset(var.country_codes)

  name = "playground-events-${each.key}"
}

# Create one Lambda per country code
resource "aws_lambda_function" "country_lambdas" {
  for_each = toset(var.country_codes)

  function_name = "playground-service-${each.key}"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  role          = aws_iam_role.lambda_role.arn
  filename      = "../dist/${each.key}.zip"
  source_code_hash = filebase64sha256("../dist/${each.key}.zip")
}

# resource "aws_sqs_queue" "my_queue" {
#   name                      = "my-regular-queue"
#   delay_seconds             = 0
#   message_retention_seconds = 345600  # 4 days
#   receive_wait_time_seconds = 0
#   visibility_timeout_seconds = 30
# }
#
# resource "aws_sqs_queue" "my_queue_x" {
#   name                      = "my-regular-queue-x"
#   delay_seconds             = 0
#   message_retention_seconds = 345600  # 4 days
#   receive_wait_time_seconds = 0
#   visibility_timeout_seconds = 30
# }

