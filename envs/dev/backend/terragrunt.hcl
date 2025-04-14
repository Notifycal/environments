include "root" {
  path = find_in_parent_folders("root.hcl")
}
include "stack" {
  path = "${get_repo_root()}/stacks/${basename(get_terragrunt_dir())}/terragrunt.hcl"
}

inputs = {
  observability = {
    alert_notifier = {
      slack_channel = "#dev-alerting"
    }
    alert_config = {
      treat_missing_data = "ignore"
      notify_insufficient_data = false
    }
  }
}
