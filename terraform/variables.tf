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

variable "region_id" {
  description = "Region"
  default     = "ru-central1"
}

variable "zone" {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}

variable "image_id" {
  description = "Disk image"
}

variable "subnet_id" {
  description = "Subnet"
}

variable "private_key_path" {
  description = "Path to the private key used for ssh access"
}

variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable instance_count {
  description = "Instance count"
  default     = 1
}
