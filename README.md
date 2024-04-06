IaC describing Notifycal environments - based on AWS. Always reliable, always DRY.

# Features

1. 3 level of config per environments.
2. independent stack definitions based on directory structure.
3. `s3` backend to store environment terraform state. `local` backend if environment == "local".
4. `dynamodb` to keep lock state when backend is of type `s3`.
5. DRY opentofu-version, .terragrunt-version.
6. parameterized stack version so enviroment stacks can evolve at their own pace.
7. stack providers only include used providers accounting for minimum version defined by the module.
8. stacks allow to configure providers if the concrete provider is used.
9. local development based on [localstack](https://www.localstack.cloud/)

# Setup

1. Install [tofuutils/tenv](https://github.com/tofuutils/tenv).

## Setup for Cloud

Export the following environment variable assuming there is a `notifycal` profile set up on your workstation.

```bash
export AWS_PROFILE=notifycal
```

## Setup for local development

In order to configure aws tf provider to use localstack, it is required to update your `~/.aws/config` and `~/.aws/credentials`.

```ini
# ~/.aws/credentials

[notifycal-localstack]
aws_access_key_id = ThisIsNotReal
aws_secret_access_key = NeitherIsThis
```

```ini
# ~/.aws/config

[profile notifycal-localstack]
region = eu-west-1
ouptut = json
endpoint_url = http://localhost:4566
services = localstack-s3

[services localstack-s3]
s3 =
  endpoint_url = http://s3.localhost.localstack.cloud:4566
```

Then, before running TG it is required to export the following environment variable, as per AWS docs:

```bash
export AWS_PROFILE=notifycal-localstack
```

Above setup allows to use AWS CLI against localstack.

# environments

 - local
 - dev
 - qa

## Stacks

 - comp1
 - comp2
 - comp3
 - localstack
