terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.73.0"
    }
  }
}

provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

module "vpc" {
  source = "../modules/vpc"
}

module "app" {
  source           = "../modules/app"
  subnet_id        = module.vpc.subnet_id
  app_disk_image   = var.app_disk_image
  db_ip            = module.db.internal_ip_address_db
  private_key_path = var.private_key_path
  public_key_path  = var.public_key_path
  enable_provision = false
}

module "db" {
  source           = "../modules/db"
  subnet_id        = module.vpc.subnet_id
  db_disk_image    = var.db_disk_image
  private_key_path = var.private_key_path
  public_key_path  = var.public_key_path
  enable_provision = false
}

resource "local_file" "generate_ansible_inventory" {
  filename = var.ansible_inventory
  content = templatefile("files/inventory.tpl", {
    app_ip_address         = module.app.external_ip_address_app,
    db_ip_address          = module.db.external_ip_address_db,
    db_internal_ip_address = module.db.internal_ip_address_db
  })

  provisioner "local-exec" {
    command = "chmod a-x ${self.filename}"
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "mv ${self.filename} ${self.filename}.backup"
    on_failure = continue
  }
}
