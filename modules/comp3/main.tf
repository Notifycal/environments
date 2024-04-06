variable "global_var" {
  type = string
}
variable "comp_specific" {
  type = string
}
variable "comp1_dependency" {
  type = string
}
variable "comp2_dependency" {
  type = string
}

resource "aws_s3_bucket" "test" {
  bucket = "notifycal-sj11-test-${var.environment}"
}

resource "aws_s3_object" "test_object" {
  key    = "testing_object_DELETE_ME"
  bucket = aws_s3_bucket.test.id
  content = <<EOT
  ${var.global_var}
  ${var.environment}
  ${var.comp_specific}
  dependency comp1: ${var.comp1_dependency}
  dependency comp2: ${var.comp2_dependency}
  EOT
}

output "test_comp3" {
  value = aws_s3_object.test_object.arn
}
