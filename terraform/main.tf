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

resource "aws_iam_role_policy" "lambda_sqs_policy" {
  name = "lambda-sqs-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "arn:aws:sqs:us-east-1:933754265105:playground-events-*"
      }
    ]
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
  reserved_concurrent_executions = 2
}

resource "aws_lambda_event_source_mapping" "sqs_triggers" {
  for_each = toset(var.country_codes)

  event_source_arn = aws_sqs_queue.country_queues[each.key].arn
  function_name    = aws_lambda_function.country_lambdas[each.key].arn

  batch_size       = 10
  enabled          = true
}
