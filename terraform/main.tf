terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.73.0"
    }
  }
}

provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}
