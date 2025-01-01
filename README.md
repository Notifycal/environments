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

## Service Registration / Service Discovery

### Registration

We're using a simple approach where each stack will register itself if required. This is configurable with a boolean `register` flag in `stacks/<stack>/source.json`.

The registration is against SSM, using a parameter name/key of the following shape:
```
/notifycal/<environment>/<stack>/url
```

### Discovery

As this applies mostly (uniquely?) to SPAs, each SPA will need to define a `config.skel.js` file:

Example `.skel.js` file:
```js
// It's not valid JS yet.
window.globalConfig = {
  GOOGLE_CLIENT_ID: ${googleClientId},
  BACKEND_BASE_URL: ${backendBaseUrl},
  STATIC_LANDING_URL: ${staticLandingUrl}
};
```

We also have a `mappings.json` file in this repo that maps skel templated "values" to SSM parameters:

```json
{
  "googleClientId": "/notifycal/${environment}/providers/google/oauth2/client_secret",   // Not stack-dependant
  "backendBaseUrl": "/notifycal/${environment}/backend/url",
  "staticLandingUrl": "/notifycal/${environment}/static-landing/url",
}
```

Note how the mappings file also exposes `environment` as something to template/interpolate.

Now we can run the `service-discovery.py` program/script to generate a final config file for a given environment. This scripts resolves the `.skel.js` mappings with `mappings.json`, `environment` with the environment name, and retrieves each key from SSM.

```
$ python service-registration/service-discovery.py \
  --environment prod \
  --skel_file frontend.skel.js \
  --mappings_file mappings.json > config.js
```

If a key is either not found in the mapping.json file, or in SSM, we'll automatically set it to `null`. That should trigger a failure when the frontend tries to process the config.

#### Sample generated config.js file
```js
window.globalConfig = {
  GOOGLE_CLIENT_ID: 'XXXXX-XXXXXXX.apps.googleusercontent.com',
  BACKEND_BASE_URL: "https://apidev.notifycal.com",
  // Example, in case a key is not in SSM or cannot resolve the mapping.
  STATIC_LANDING_URL: null    
};
```

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
