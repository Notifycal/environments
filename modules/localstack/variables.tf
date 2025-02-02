variable "name" {
  type    = string
  default = "localstack-main"
}

variable "volume_dir" {
  type = string
  // GOTCHA: this directory structure needs creating the very first time.
  default = "~/.cache/localstack/volume"
}

variable "docker_version" {
  type    = string
  default = "4.0.3"
}

variable "debug" {
  type    = string
  default = "0"
}

variable "enabled_services" {
  type    = list(string)
  default = ["logs", "iam", "apigateway", "s3", "lambda", "dynamodb", "ssm", "sqs", "sns", "acm", "events"]
}

variable "expose_frontend" {
  type    = bool
  default = false
}
