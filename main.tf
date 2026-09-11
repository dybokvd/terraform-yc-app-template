terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.87.0"
    }
  }
  required_version = ">= 0.13"
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
    initialize_params {
      image_id = "fd806u1okplml22f4pmo" # Ubuntu 22.04 LTS image
      size     = 10                     # GB
      type     = "network-hdd"
    }
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