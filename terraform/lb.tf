resource "yandex_lb_network_load_balancer" "app_lb" {
  name = "app-lb"
  type = "external"

  listener {
    name        = "app-lb-listener"
    port        = 80
    target_port = 9292

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.app_lb_target_group.id

    healthcheck {
      name = "http"
      tcp_options {
        port = 9292
      }
    }
  }
}

resource "yandex_lb_target_group" "app_lb_target_group" {
  name      = "app-lb-target-group"
  folder_id = var.folder_id
  region_id = var.region_id

  dynamic "target" {
    for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
    content {
      subnet_id = var.subnet_id
      address   = target.value
    }
  }
}
