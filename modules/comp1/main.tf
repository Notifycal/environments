variable "global_var" {
  type = string
}
variable "comp_specific" {
  type = string
}

resource "null_resource" "test" {
  triggers = {
    
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "echo $ENV $VAR1 $GLOBAL"
    environment = {
      ENV = var.environment
      VAR1 = var.comp_specific
      GLOBAL = var.global_var
    }
  }
}

output "test_comp1" {
  value = "${var.environment} / ${var.global_var} / ${var.comp_specific}"
}
