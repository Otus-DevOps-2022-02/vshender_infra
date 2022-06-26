variable "service_account_key_file" {
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
  default     = "ru-central1-a"
}

variable "bucket_name" {
  description = "tfstate storage bucket name"
  default     = "otus-vshender-tfstate-storage"
}

variable "service_account_id" {
  description = "Service account ID"
}
