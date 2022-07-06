variable "subnet_id" {
  description = "Subnet for modules"
}

variable "app_disk_image" {
  description = "Disk image for reddit app"
  default     = "reddit-db-base"
}

variable "db_ip" {
  description = "MongoDB IP address"
}

variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable "private_key_path" {
  description = "Path to the private key used for ssh access"
}

variable "enable_provision" {
  description = "Whether to enable the application provisioning"
  default     = true
}
