variable "ssh_public_key" {
  type        = string
  description = "Public key installed on the virtual machine via cloud-init"
}

# Must match the default user of the image specified in boot_disk_configuration
variable "user" {
  type        = string
  description = "User the public key is installed for via cloud-init"
  default     = "ubuntu"
}

variable "project_name" {
  type        = string
  description = "Base name used as a prefix for all resource names"
  default     = "terraform-yc-app-template"
}

variable "vm_configuration" {
  type = object({
    cores  = number
    memory = number
  })

  description = "Number of CPU cores and amount of memory in GB allocated to the virtual machine"

  default = {
    cores  = 2
    memory = 4 # GB
  }
}

variable "boot_disk_configuration" {
  type = object({
    image_id = string
    size     = number
    type     = string
  })

  description = "OS image, size in GB and disk type used for the virtual machine's boot disk"

  default = {
    image_id = "fd806u1okplml22f4pmo" # Ubuntu 22.04 LTS image
    size     = 10                     # GB
    type     = "network-hdd"
  }

  validation {
    condition     = contains(["network-hdd", "network-ssd", "network-ssd-nonreplicated"], var.boot_disk_configuration.type)
    error_message = "boot_disk.type must be one of: network-hdd, network-ssd, network-ssd-nonreplicated."
  }
}
