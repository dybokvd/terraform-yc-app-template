resource "yandex_vpc_network" "network" {
  name        = local.network_name
  description = "Groups all the managed resources"
}

resource "yandex_vpc_subnet" "ru_central1_a" {
  name           = local.subnet_ru_central1_a_name
  description    = "Groups the managed resources located in the ru-central1-a availability zone"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

resource "yandex_vpc_security_group" "vm" {
  name        = local.security_group_vm_name
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
  name = local.vm_name

  resources {
    cores  = var.vm_configuration.cores
    memory = var.vm_configuration.memory
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
    # Public key installed for the specific user via cloud-init
    ssh-keys = "${var.user}:${var.ssh_public_key}"
  }

  # Allow Terraform to stop the resource if needed when applying changes
  allow_stopping_for_update = true
}

resource "yandex_compute_disk" "boot_disk" {
  name = local.boot_disk_name

  image_id = var.boot_disk_configuration.image_id
  size     = var.boot_disk_configuration.size
  type     = var.boot_disk_configuration.type

  lifecycle {
    # Prevent accidental resource destruction by making Terraform fail instead
    prevent_destroy = true
  }
}

resource "yandex_vpc_address" "public_ip" {
  name = local.public_ip_name

  external_ipv4_address {
    zone_id = "ru-central1-a"
  }

  # To delete a resource created with this flag using Terraform, you must first disable this setting through the Yandex Cloud web interface
  deletion_protection = true
}
