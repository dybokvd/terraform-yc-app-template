# Terraform Template for Application Development

## About the Configuration

### What This Is

This Terraform configuration template lets you manage infrastructure on Yandex Cloud for developing, testing and operating applications, following the Infrastructure as Code approach.

Managing infrastructure this way, instead of configuring resources manually, comes with several benefits, such as reproducibility, version control and cost efficiency.

Currently, the project supports managing infrastructure in a single environment. The template will later be extended to manage several independent environments.

The state of the managed infrastructure is stored in Yandex Object Storage, an S3-compatible storage service, which reduces the risk of state drift across different hosts.

### What Infrastructure Is Created

The managed infrastructure consists of a minimal set of resources, which simplifies maintenance and keeps costs to a minimum. At the same time, it is self-contained and suitable for systems made up of a large number of components.

First, the configuration explicitly creates the necessary networking infrastructure:

- a network that the resources belong to;
- a subnet in the `ru-central1-a` availability zone.

The resources are then created inside this network:

- a virtual machine;
- an HDD disk attached to the virtual machine, used to store the operating system and other data;
- a static public IP address assigned to the virtual machine.

The disk and the IP address are managed independently of the virtual machine. This makes it possible to preserve the data and the IP address in cases where Terraform has to recreate the virtual machine — for example, when its configuration changes.

The compute resources are created within a single availability zone, which carries the risk of a complete system outage. If your system has higher availability requirements, consider a more advanced configuration with resources spread across multiple availability zones and traffic balancing between them.

## Initial Setup

### Tools You Need to Install

Before using this configuration, make sure you have Terraform installed and configured to work with Yandex Cloud. You can do this by following [this guide](https://yandex.cloud/en/docs/ydb/terraform/install#terraform-install-on-dif-os).

You'll also need the `yc` CLI to work with Yandex Cloud. Install it by following [this guide](https://yandex.cloud/en/docs/cli/operations/install-cli).

### One-Time Setup

Configure Terraform to connect to the storage holding the state of the managed infrastructure:

1. Create a service account in the Yandex Cloud Console, granting it the `editor` role.

2. Create keys to connect Terraform to the object storage you want to use as a backend.

3. Save the generated keys and export them as environment variables:

```
export ACCESS_KEY="..."                                                   
export SECRET_KEY="..."
```

4. Initialize the project using the exported keys:

```
terraform init -backend-config="access_key=$ACCESS_KEY" -backend-config="secret_key=$SECRET_KEY"
```

Authenticate with Yandex Cloud via `yc`:

```
yc init --username=...
```

## Applying the Configuration

### How to Apply Infrastructure Changes After Code Changes

1. Generate the required tokens:

```
export YC_TOKEN=$(yc iam create-token)                     
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)

printenv | grep "YC"
```

If you haven't authenticated yet, `yc` will open a page in your browser where you can do so.

2. Make your changes to the configuration, then preview the changes Terraform is about to apply to the current infrastructure:

```
terraform plan
```

3. Apply the proposed changes and confirm your choice:

```
terraform apply
```

The output will include the IP address of the running virtual machine.

### How to Remove the Created Resources

To remove the managed infrastructure, run:

```
terraform destroy
```

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.