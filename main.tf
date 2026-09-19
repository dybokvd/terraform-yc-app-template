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

resource "yandex_vpc_network" "network" {
  name        = "terraform-yc-app-template-network"
  description = "Groups all the managed resources"
}

resource "yandex_vpc_subnet" "ru_central1_a" {
  name           = "terraform-yc-app-template-subnet-ru-central1-a"
  description    = "Groups the managed resources located in the ru-central1-a availability zone"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

resource "yandex_vpc_security_group" "vm" {
  name        = "terraform-yc-app-template-security-group-vm"
  description = "Controls traffic to and from virtual machines"
  network_id  = yandex_vpc_network.network.id

  ingress {
    protocol       = "TCP"
    description    = "Allows SSH connections for server administration"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Allows HTTP connections for web applications"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Allows HTTPS connections for web applications"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Allows all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
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
    # Prevents the boot disk from being automatically deleted when the virtual machine is deleted
    auto_delete = false
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.ru_central1_a.id
    # Assign a public IP address
    nat                = true
    nat_ip_address     = yandex_vpc_address.public_ip.external_ipv4_address[0].address
    security_group_ids = [yandex_vpc_security_group.vm.id]
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

resource "yandex_vpc_address" "public_ip" {
  name = "terraform-yc-app-template-public-ip"

  external_ipv4_address {
    zone_id = "ru-central1-a"
  }

  # To delete a resource created with this flag using Terraform, you must first disable this setting through the Yandex Cloud web interface
  deletion_protection = true
}
