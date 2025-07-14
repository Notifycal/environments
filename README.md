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

### Bootstrap environment/create environment secrets

When first creating an environment, we need to explicitly apply the `env_secrets` stack.

```bash
$ cd env_secrets
$ terragrunt apply
```

This stack only runs when invoked explicitly from its folder thanks to Terragrunt's `exclude` mechanism.

## Local Development

You might pick one of the following options depending on what you are doing/want to achievea and the stack you are working on:

### frontend

For now, you should run frontend on Vite i.e. `npm run dev` while being at frontend repo. Depending on what backend frontend is configured to run against, you might need to tweak frontend/config/config.local.js by default config assumes frontend will be run against backend-on-express.

IaC has not yet been optimised to deploy frontend on Localstack - although - not much is left to achieve it.
TODO:
 - adapt [post apply hook](https://github.com/Notifycal/frontend/blob/3ca659677e5ebf2e78a17de5d240579d1388e79e/ci/post-apply.sh#L49).
 - Write a new post apply hook so one can build, package and deploy app on s3/localstack. Similar to the `LOCAL_DEV=true` explained later on this document. Motivation: at some point we might want to test out code changes as well as infra changes before exposing a PR. TLDR: shorthen the development loop and a bit less of _rocket-science_.
 - Enable reverse proxy in localstack stack so that developers can use frontend up on http://localhost:5173 just like when running frontend on Vite. For now, disabled to avoid port clashing.
 - Make sure service registration works for frontend by passing the right values. E.g backendUrl. ATM, backend stack stores a value in SSM that doesn't reflect where APIGW is deployed at on localstack.

### backend

Two options here:

1) Running backend on Express i.e. `npm run dev` while being at backend repo. This option offers the shortest development loop in case you are only interested in making changes in lambdas exposed through API. It still relies on AWS resources created on Localstack such us DynamoDB, etc. So make sure, `tg apply` localstack stack for environments/envs/local/localstack.

2) Running the whole backend on Localstack. For a higher degree of confidence, you can apply IaC against Localstack and use it as if it was hosted in AWS. First of all, you need to export AWS_PROFILE, as mentioned above - so that the terraform AWS provider uses the profile that points at Localstack. If you are also interested in testing local tf code or an adhoc build, even altogether if you wanted too, keep reading.

### Deploying local TF code (that is not released yet)
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

This will run any existing `ci/pre-plan-apply.local.sh` (or `ci/post-apply.local.sh`) living in the repository, unless you've [disabled the hooks](#disable-hooks-using-env-vars).

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

### TF/TG Provider Lock for multiple architectures
```bash
terragrunt run-all providers lock -platform=linux_amd64 -platform=darwin_arm64
```

### Disable hooks using env vars.

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

## Prevent Environment Destruction via `.keep-envs/`

By default, our cleanup workflow will destroy all `dev*` environments on a scheduled basis or when explicitly triggered. However, you can prevent specific environments from being destroyed by using the `.keep-envs/` mechanism.

> If a file with the same name as the environment exists inside `.keep-envs/`, that environment will be **excluded** from automated destruction.
>
> The file does not need any content. Its **presence alone** is enough.

---

### Example

Suppose you want to prevent `dev-dan` from being destroyed:

```bash
touch .keep-envs/dev-dan
git add .keep-envs/dev-dan
git commit -m "Keep dev-dan for debugging"
git push
```

To allow it to be destroyed again:

```bash
git rm .keep-envs/dev-dan
git commit -m "Allow dev-dan to be cleaned up"
git push
```

---

### Directory overview

```
.keep-envs/
├── dev-dan      # Will NOT be destroyed
├── dev-foo      # Will NOT be destroyed
# (other dev-* environments without a file will be destroyed normally)
```

---

### ⚠️ Notes

- This only affects `dev*` environments.
- The `.keep-envs/` folder is committed to the repo, so protection state is version-controlled.
- The `.gitkeep` file is ignored by the cleanup logic — it just ensures the folder exists.
