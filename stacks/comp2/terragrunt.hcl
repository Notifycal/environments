dependency "comp1" {
  config_path = "${get_terragrunt_dir()}/../comp1"
  mock_outputs = {
    test_comp1 = ""
  }
  mock_outputs_allowed_terraform_commands = ["init"]
}

inputs = {
  comp1_dependency = dependency.comp1.outputs.test_comp1
}