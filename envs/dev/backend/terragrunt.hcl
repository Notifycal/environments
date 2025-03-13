include "root" {
  path = find_in_parent_folders("root.hcl")
}
include "stack" {
  path = "${get_repo_root()}/stacks/${basename(get_terragrunt_dir())}/terragrunt.hcl"
}

inputs = {
  observability = {
    slack_webhook_url = "https://hooks.slack.com/services/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"
    slack_channel     = "#dev-alerting"
  }
}
