# main.tf

provider "aws" {
  region  = "us-east-1"
  profile = "playground"   # name of your AWS CLI profile
}

resource "aws_sqs_queue" "my_queue" {
  name                      = "my-regular-queue"
  delay_seconds             = 0
  message_retention_seconds = 345600  # 4 days
  receive_wait_time_seconds = 0
  visibility_timeout_seconds = 30
}
