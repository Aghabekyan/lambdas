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





#########################################################
# Variables (assumes these are defined in variables.tf)
# var.aws_account_id
# var.aws_region
# var.country_codes = ["us", "de", "fr", ...]
#########################################################

# --------------------------------------
# IAM Role for API Gateway to access SQS
# --------------------------------------
resource "aws_iam_role" "apigw_sqs_role" {
  name = "apigw-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "apigateway.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "apigw_sqs_policy" {
  name = "apigw-sqs-policy"
  role = aws_iam_role.apigw_sqs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["sqs:SendMessage"],
      Resource = [
        for c in var.country_codes : "arn:aws:sqs:${var.aws_region}:${var.aws_account_id}:playground-events-${c}"
      ]
    }]
  })
}

# ------------------------------
# API Gateway REST API
# ------------------------------
resource "aws_api_gateway_rest_api" "country_api" {
  name = "country-events-api"
}

# Root resource
data "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.country_api.id
  path        = "/"
}

# Country sub-resources (e.g., /us, /de)
resource "aws_api_gateway_resource" "country_resource" {
  for_each    = toset(var.country_codes)
  rest_api_id = aws_api_gateway_rest_api.country_api.id
  parent_id   = data.aws_api_gateway_resource.root.id
  path_part   = each.key
}

# POST method for each country
resource "aws_api_gateway_method" "country_post" {
  for_each       = aws_api_gateway_resource.country_resource
  rest_api_id    = aws_api_gateway_rest_api.country_api.id
  resource_id    = each.value.id
  http_method    = "POST"
  authorization  = "NONE"
}

# Direct SQS integration
resource "aws_api_gateway_integration" "country_sqs" {
  for_each = aws_api_gateway_method.country_post

  rest_api_id             = aws_api_gateway_rest_api.country_api.id
  resource_id             = each.value.resource_id
  http_method             = each.value.http_method
  type                    = "AWS"
  integration_http_method = "POST"

  # URI points to the SQS queue
  uri = "arn:aws:apigateway:${var.aws_region}:sqs:path/${var.aws_account_id}/playground-events-${each.key}"

  # API Gateway role ARN
  credentials = aws_iam_role.apigw_sqs_role.arn

  request_templates = {
    "application/json" = <<EOF
Action=SendMessage&Version=2012-11-05&MessageBody=$util.urlEncode($input.body)
EOF
  }
}

# Deploy the API
resource "aws_api_gateway_deployment" "country_api_deploy" {
  depends_on = [aws_api_gateway_integration.country_sqs]
  rest_api_id = aws_api_gateway_rest_api.country_api.id
}