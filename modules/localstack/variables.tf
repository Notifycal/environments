variable "name" {
  type    = string
  default = "localstack-main"
}

variable "volume_dir" {
  type    = string
  default = "~/.cache/localstack/volume"
}

variable "docker_version" {
  type    = string
  default = "3.3"
}

variable "debug" {
  type    = string
  default = "0"
}