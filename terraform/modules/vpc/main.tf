terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.73.0"
    }
  }
}

resource "yandex_vpc_network" "app_network" {
  name = "reddit-app-network"
}

resource "yandex_vpc_subnet" "app_subnet" {
  name           = "reddit-app-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.app_network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}
