# environments
[![CI/CD](https://github.com/Notifycal/environments/actions/workflows/cicd.yaml/badge.svg?event=push)](https://github.com/Notifycal/environments/actions/workflows/cicd.yaml)


IaC describing Notifycal environments - based on AWS. Always reliable, always DRY.

## Features

1. 3 level of config per environments.
2. independent stack definitions based on directory structure.
3. `s3` backend to store environment terraform state. `local` backend if environment == "local".
4. `dynamodb` to keep lock state when backend is of type `s3`.
5. DRY opentofu-version, .terragrunt-version.
6. parameterized stack version so enviroment stacks can evolve at their own pace.
7. stack providers only include used providers accounting for minimum version defined by the module.
8. stacks allow to configure providers if the concrete provider is used.
9. local development based on [localstack](https://www.localstack.cloud/)
10. a poor man's version of [service registration and discovery](#service-registration)

## Setup

1. Install [tofuutils/tenv](https://github.com/tofuutils/tenv).

### Setup for Cloud

Export the following environment variable assuming there is a `notifycal` profile set up on your workstation.

```bash
export AWS_PROFILE=notifycal
```

### Setup for local development

Nothing is required to be set so local environment can talk to localstack. Localstack docker container created by terragrunt needs some directory structure so it can map its volume. Therefore, unless [specified otherwise](https://github.com/Notifycal/environments/blob/ed5ef373d90a9cc804403e972209fb393d0e08e8/modules/localstack/variables.tf#L8) the following command needs to be executed the very first time docker localstack runs on your workstation.:

```ini
mkdir -p ~/.cache/localstack/volume
```

Everything else has been defined in terragrunt config.

#### AWS CLI against localstack

In order to configure aws CLI to use localstack, it is required to update your `~/.aws/config` and `~/.aws/credentials`.

```ini
# ~/.aws/credentials

[notifycal-localstack]
aws_access_key_id = foo
aws_secret_access_key = bar
```

```ini
# ~/.aws/config

[profile notifycal-localstack]
region = eu-west-1
ouptut = json
endpoint_url = http://localhost:4566
```

Then, use the profile configured above before running AWS CLI, as per AWS docs:

```bash
export AWS_PROFILE=notifycal-localstack
```

#### Deploying local TF code (that is not released yet)
In order to do this, we have to point Terragrunt to the absolute path of the local copy of the stack. This is done by modifying `base_source_url` in `stacks/<stack>/source.json`.

> [!CAUTION]
> Never commit this change. It's only for local deployment.

```diff
## stacks/backend/source.json
{
  - "base_source_url": "git@github.com:Notifycal/backend.git//tf",

  + "base_source_url": "/Users/dan/dev/personal/notifycal/backend//tf",
  ...
}
```

Notice the double slash (`//`) before `tf`. This tells TF that the module is the entire backend folder, but it'll only be running code from within the `tf` folder.

#### Creating ad-hoc build through .local hooks
The above steps only cover deploying local TF code, but not local application code.

During regular deployment, we'll download a release from Github and deploy it. But that requires the code to be merged and released, which won't be ideal for local development both against localstack or the dev environment.

In order to create ad-hoc builds, we expect the stack to expose a `ci/pre-plan-apply.local.sh` (or `ci/post-apply.local.sh`) script, in a similar fashion that it exposes a `ci/pre-plan-apply.sh` (and `ci/post-apply.sh`) for remote environments.

Finally, just set the `LOCAL_DEV` env var to `true` before running Terragrunt.

```bash
# Ideal for a single command/stack
$ LOCAL_DEV=true terragrunt apply
```
or 
```bash
# More useful for a session of local-dev across different stacks, etc.
$ export LOCAL_DEV=true
$ terragrunt apply
```

This will run any existing `ci/pre-plan-apply.local.sh` (or `ci/post-apply.local.sh`) living in the repository

#### Provider caching

When running `terragrunt` locally, we can enable the Provider cache so different environments don't have to download the same providers every time.

To enable it, just set `TERRAGRUNT_PROVIDER_CACHE=1` (on .bashrc or before execution) and it will rely on the default Provider cache folder in the user's home (check [official docs](https://terragrunt.gruntwork.io/docs/features/provider-cache-server/)).

This reduces the size of the `.terragrunt-cache/` folders within the environments/stacks, making it go from GBs to MBs.

## Pre/post hooks
- TODO.


## Service Registration
Check [the docs](./service-registration/README.md) in the `service-registration` folder

## environments

- local
- dev
- qa

## Stacks

- static-landing
- backend
- localstack

## Tips and tricks

### Disable pre-apply/post-apply hooks using env vars.

You can define any of the following environment variables when running `terragrunt` in order to stop the pre-plan-apply/post-apply hooks. This is useful for local development.

- `TG_SKIP_HOOKS`: Disables both `pre` and `post` hooks.
- `TG_SKIP_PRE_PLAN_HOOK`: Disables `pre` hook.
- `TG_SKIP_POST_APPLY_HOOK`: Disables `post` hook.

Example:

```bash
TG_SKIP_PRE_PLAN_HOOK=true terragrunt plan

# or

export TG_SKIP_PRE_PLAN_HOOK=true
terragrunt plan
```
