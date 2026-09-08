terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }

    local = {
      source = "hashicorp/local"
    }
  }
}

# провайдер

provider "yandex" {
  zone = "ru-central1-b"
}


# создание двух ВМ

resource "yandex_compute_instance" "vm" {
  count = 2

  name        = "vm${count.index}"
  platform_id = "standard-v1"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd83ergat2e815oohe7o"
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519_nopass.pub")}"
  }
}


# создание сети

resource "yandex_vpc_network" "network1" {
  name = "network1"
}


# создание подсети

resource "yandex_vpc_subnet" "subnet1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  v4_cidr_blocks = ["172.24.8.0/24"]
  network_id     = yandex_vpc_network.network1.id
}


# создание целевой группы

resource "yandex_lb_target_group" "group1" {
  name = "group1"

  dynamic "target" {
    for_each = yandex_compute_instance.vm

    content {
      subnet_id = yandex_vpc_subnet.subnet1.id
      address   = target.value.network_interface[0].ip_address
    }
  }
}


# балансировщик

resource "yandex_lb_network_load_balancer" "balancer1" {
  name                = "balancer1"
  deletion_protection = false

  listener {
    name        = "my-lb1"
    port        = 80
    target_port = 80

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.group1.id

    healthcheck {
      name = "http"

      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
