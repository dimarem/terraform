# Создание VPC для ВМ
resource "yandex_vpc_network" "vm" {
  name        = var.vpc["name"]
  description = "Сеть для ВМ ${var.ci["name"]}"
}

# Создание подсети для ВМ
resource "yandex_vpc_subnet" "vm" {
  name           = var.vpc_subnet["name"]
  zone           = var.zone
  network_id     = yandex_vpc_network.vm.id
  v4_cidr_blocks = var.vpc_subnet["v4_cidr_blocks"]
  description    = "Подсеть для ВМ ${var.ci["name"]}"
}

# Получение актуального image_id
data "yandex_compute_image" "vm" {
  family = "container-optimized-image"
}

# Создание загрузочного диска
resource "yandex_compute_disk" "vm" {
  name        = var.cd["name"]
  type        = var.cd["type"]
  size        = var.cd["size"]
  zone        = var.zone
  image_id    = yandex_compute_image.vm.id
  description = "Загрузочный диск для ВМ ${var.ci["name"]}"
}

# Создание ВМ
resource "yandex_compute_instance" "demo" {
  name        = var.ci["name"]
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
    nat       = var.ci["nat"]
  }
}
