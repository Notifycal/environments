variable "global_var" {
  type = string
}
variable "comp_specific" {
  type = string
}
variable "comp1_dependency" {
  type = string
}

resource "random_id" "test" {
  keepers = {
    environment = var.environment
    dependency = var.comp1_dependency
    comp_specific = var.comp_specific
    global_var = var.global_var
  }

  byte_length = 8
}

output "test_comp2" {
  value       = "${var.environment} / ${var.comp_specific} / ${var.global_var} / ${var.comp1_dependency}"
}
