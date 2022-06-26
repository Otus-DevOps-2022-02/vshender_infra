terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.73.0"
    }
  }
}

resource "yandex_compute_instance" "db" {
  name = "reddit-db"

  labels = {
    tags = "reddit-db"
  }

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.db_disk_image
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}

resource "null_resource" "db_provisioning" {
  count = var.enable_provision ? 1 : 0
  triggers = {
    db_id = yandex_compute_instance.db.id
  }

  connection {
    type        = "ssh"
    host        = yandex_compute_instance.db.network_interface.0.nat_ip_address
    user        = "ubuntu"
    agent       = false
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    content = templatefile("${path.module}/files/mongod.conf.tmpl", {
      db_ip = yandex_compute_instance.db.network_interface.0.ip_address
    })
    destination = "/tmp/mongod.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv -f /tmp/mongod.conf /etc/mongod.conf",
      "sudo systemctl restart mongod"
    ]
  }
}
