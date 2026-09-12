terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.87.0"
    }
  }
  required_version = ">= 0.13"

  # S3 backend works here because Yandex Object Storage is S3-compatible
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    bucket = "dibok396-terraform-states-bucket"
    region = "ru-central1"
    key    = "terraform-yc-app-template/production/terraform.tfstate"

    # Skip AWS-specific checks that do not apply to Yandex Object Storage
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  # Default availability zone for resources that don't specify one explicitly
  zone = "ru-central1-a"
}

resource "yandex_compute_instance" "vm" {
  name = "terraform-yc-app-template-vm"

  resources {
    cores  = 2
    memory = 4 # GB
  }

  scheduling_policy {
    # Prevent unexpected resource termination by Yandex Cloud
    preemptible = false
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot_disk.id
  }

  network_interface {
    subnet_id = "e9b6ninrcea75f4ors6f"
    # Assign a dynamic public IP address
    nat = true
  }

  metadata = {
    # Public key installed for the "ubuntu" user via cloud-init
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  # Allow Terraform to stop the resource if needed when applying changes
  allow_stopping_for_update = true
}

resource "yandex_compute_disk" "boot_disk" {
  name = "terraform-yc-app-template-boot-disk"

  image_id = "fd806u1okplml22f4pmo" # Ubuntu 22.04 LTS image
  size     = 10                     # GB
  type     = "network-hdd"

  lifecycle {
    # Prevent accidental resource destruction by making Terraform fail instead
    prevent_destroy = true
  }
}