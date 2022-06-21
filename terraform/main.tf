terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.73.0"
    }
  }
}

provider "yandex" {
  service_account_key_file = "../yc-svc-key.json"
  cloud_id                 = "b1gfri8c7lvn2hi12p7g"
  folder_id                = "b1go0bbc4eormvjuv1mq"
  zone                     = "ru-central1-a"
}

resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашем задании
      image_id = "fd89dv82hadttcirp1hr"
    }
  }

  network_interface {
    # Указан id подсети default-ru-central1-a
    subnet_id = "e9bqom95bd1o3fkemarr"
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/appuser.pub")}"
  }
}
