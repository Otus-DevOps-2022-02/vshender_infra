variable "service_account_key_file" {
  # Описание переменной
  description = "Path to the Yandex.Cloud service account key file"
}

variable "cloud_id" {
  description = "Cloud"
}

variable "folder_id" {
  description = "Folder"
}

variable "zone" {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}

variable "app_disk_image" {
  description = "Disk image for the reddit app"
  default     = "reddit-app-base"
}

variable "db_disk_image" {
  description = "Disk image for the reddit DB"
  default     = "reddis-db-base"
}

variable "private_key_path" {
  description = "Path to the private key used for ssh access"
}

variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable "ansible_inventory" {
  description = "Path to the Ansible inventory file to generate"
  default     = "../../ansible/inventory"
}
