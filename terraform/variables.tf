variable "country_codes" {
  type    = list(string)
  default = ["us", "am"]  # add your countries here
}
variable "aws_account_id" {
  description = "AWS account ID"
  type        = number
  default     = 933754265105
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "api_stage_name" {
  type    = string
  default = "dev"
}