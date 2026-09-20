
locals {
  vm_name                   = "${var.project_name}-vm"
  boot_disk_name            = "${var.project_name}-boot-disk"
  public_ip_name            = "${var.project_name}-public-ip"
  network_name              = "${var.project_name}-network"
  subnet_ru_central1_a_name = "${var.project_name}-subnet-ru-central1-a"
  security_group_vm_name    = "${var.project_name}-security-group-vm"
}
