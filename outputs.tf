output "public_ip" {
  description = "Public IP address of the virtual machine"
  value       = yandex_compute_instance.vm.network_interface[0].nat_ip_address
} 