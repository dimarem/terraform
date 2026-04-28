locals {
  suffix          = random_string.suffix.result
  vpc_name        = "${var.vpc["name"]}-${local.suffix}"
  vpc_subnet_name = "${var.vpc_subnet["name"]}-${local.suffix}"
  cd_name         = "${var.cd["name"]}-${local.suffix}"
  vm_name         = "${var.ci["name"]}-${local.suffix}"
}

# Создание VPC для ВМ
resource "yandex_vpc_network" "vm" {
  name        = local.vpc_name
  description = "Сеть для ВМ ${local.vm_name}"
}

# Создание подсети для ВМ
resource "yandex_vpc_subnet" "vm" {
  name           = local.vpc_subnet_name
  zone           = var.zone
  network_id     = yandex_vpc_network.vm.id
  v4_cidr_blocks = var.vpc_subnet["v4_cidr_blocks"]
  description    = "Подсеть для ВМ ${local.vm_name}"
}

# Получение актуального image_id
data "yandex_compute_image" "vm" {
  family = "container-optimized-image"
}

# Создание загрузочного диска
resource "yandex_compute_disk" "vm" {
  name        = local.cd_name
  type        = var.cd["type"]
  size        = var.cd["size"]
  zone        = var.zone
  image_id    = data.yandex_compute_image.vm.id
  description = "Загрузочный диск для ВМ ${var.ci["name"]}"
}

# Создание ВМ
resource "yandex_compute_instance" "demo" {
  name        = local.vm_name
  platform_id = var.ci["platform_id"]
  zone        = var.zone
  description = "Демонстрационный пример ВМ"

  resources {
    cores  = var.ci["cores"]
    memory = var.ci["memory"]
  }

  boot_disk {
    disk_id = yandex_compute_disk.vm.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.vm.id
    nat       = var.cd["nat"]
  }

  metadata = {
    user-data = templatefile("${path.module}/cloud-init.tftpl", {
      admin_name  = var.cloud_init["admin_name"]
      ssh_pub_key = var.cloud_init["ssh_pub_key"]
      db_user     = var.cloud_init["db_user"]
      db_pass     = var.cloud_init["db_pass"]
    })
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
