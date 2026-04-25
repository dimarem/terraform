# Создание сервисного аккаунта
resource "yandex_iam_service_account" "gitlab_sa" {
  name        = var.sa_name
  description = "Наименование сервисного аккаунта, от имени которого ${var.gitlab["name"]} выполняет действия"
}

# Назначение роли сервисному аккаунту - admin
resource "yandex_resourcemanager_folder_iam_member" "gitlab_sa_admin" {
  folder_id = var.folder_id
  role      = "admin"
  member    = "serviceAccount:${yandex_iam_service_account.gitlab_sa.id}"
}

# Создание авторизованного ключа доступа
resource "yandex_iam_service_account_key" "gitlab_sa_key" {
  service_account_id = yandex_iam_service_account.gitlab_sa.id
  description        = "Авторизованный ключ доступа ${var.gitlab["name"]}"
  key_algorithm      = "RSA_2048"
}

# Создание файла .key.json с ключом доступа
resource "local_file" "key" {
  content  = <<EOH
  {
    "id": "${yandex_iam_service_account_key.gitlab_sa_key.id}",
    "service_account_id": "${yandex_iam_service_account.gitlab_sa.id}",
    "created_at": "${yandex_iam_service_account_key.gitlab_sa_key.created_at}",
    "key_algorithm": "${yandex_iam_service_account_key.gitlab_sa_key.key_algorithm}",
    "public_key": ${jsonencode(yandex_iam_service_account_key.gitlab_sa_key.public_key)},
    "private_key": ${jsonencode(yandex_iam_service_account_key.gitlab_sa_key.private_key)}
  }
  EOH
  filename = ".key.json"
}

# Создание VPC для GitLab
resource "yandex_vpc_network" "gitlab_vpc" {
  name = var.vpc["name"]
}

# Создание подсети
resource "yandex_vpc_subnet" "gitlab_subnet" {
  name           = var.vpc_subnet["name"]
  zone           = var.zone
  network_id     = yandex_vpc_network.gitlab_vpc.id
  v4_cidr_blocks = var.vpc_subnet["v4_cidr_blocks"]
}

# Получение актуального image_id
data "yandex_compute_image" "gitlab_compute_image" {
  family = "container-optimized-image"
}

# Создание загрузочного диска для VM
resource "yandex_compute_disk" "gitlab_compute_disk" {
  name     = var.compute_disk["name"]
  zone     = var.zone
  image_id = data.yandex_compute_image.gitlab_compute_image.image_id
  size     = var.compute_disk["size"]

  lifecycle {
    ignore_changes = [image_id]
  }
}

# Создание VM для GitLab Runner
resource "yandex_compute_instance" "gitlab_compute_instance" {
  name        = var.compute_instance["name"]
  zone        = var.zone
  platform_id = var.compute_instance["platform_id"]

  resources {
    cores  = var.compute_instance["cores"]
    memory = var.compute_instance["memory"]
  }

  boot_disk {
    disk_id = yandex_compute_disk.gitlab_compute_disk.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.gitlab_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys  = var.compute_instance["ssh_keys"]
    user-data = var.compute_instance["user_data"]
  }
}

# Создание экземпляра Gitlab
resource "yandex_gitlab_instance" "gitlab_instance" {
  name                      = var.gitlab["name"]
  resource_preset_id        = var.gitlab["resource_preset_id"]
  disk_size                 = var.gitlab["disk_size"]
  admin_login               = var.gitlab["admin_login"]
  admin_email               = var.gitlab["admin_email"]
  domain                    = var.gitlab["domain"]
  approval_rules_id         = var.gitlab["approval_rules_id"]
  backup_retain_period_days = var.gitlab["backup_retain_period_days"]
  subnet_id                 = yandex_vpc_subnet.gitlab_subnet.id
}
