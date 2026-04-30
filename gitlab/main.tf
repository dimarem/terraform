# Создание сервисного аккаунта
resource "yandex_iam_service_account" "gitlab" {
  name        = var.sa_name
  description = "Наименование сервисного аккаунта, от имени которого ${var.gitlab["name"]} выполняет действия"
}

# Назначение роли сервисному аккаунту - admin
resource "yandex_resourcemanager_folder_iam_member" "admin" {
  folder_id = var.folder_id
  role      = "admin"
  member    = "serviceAccount:${yandex_iam_service_account.gitlab.id}"
}

# Создание авторизованного ключа доступа
resource "yandex_iam_service_account_key" "gitlab" {
  service_account_id = yandex_iam_service_account.gitlab.id
  description        = "Авторизованный ключ доступа ${var.gitlab["name"]}"
  key_algorithm      = "RSA_2048"
}

# Создание файла .key.json с ключом доступа
resource "local_file" "key" {
  content  = <<EOH
  {
    "id": "${yandex_iam_service_account_key.gitlab.id}",
    "service_account_id": "${yandex_iam_service_account.gitlab.id}",
    "created_at": "${yandex_iam_service_account_key.gitlab.created_at}",
    "key_algorithm": "${yandex_iam_service_account_key.gitlab.key_algorithm}",
    "public_key": ${jsonencode(yandex_iam_service_account_key.gitlab.public_key)},
    "private_key": ${jsonencode(yandex_iam_service_account_key.gitlab.private_key)}
  }
  EOH
  filename = ".key.json"
}

# Создание VPC для GitLab
resource "yandex_vpc_network" "gitlab" {
  name = var.vpc["name"]
}

# Создание подсети
resource "yandex_vpc_subnet" "gitlab" {
  name           = var.vpc_subnet["name"]
  zone           = var.zone
  network_id     = yandex_vpc_network.gitlab.id
  v4_cidr_blocks = var.vpc_subnet["v4_cidr_blocks"]
}

# Получение актуального image_id
data "yandex_compute_image" "gitlab" {
  family = "container-optimized-image"
}

# Создание загрузочного диска для VM
resource "yandex_compute_disk" "gitlab" {
  name     = var.compute_disk["name"]
  zone     = var.zone
  image_id = data.yandex_compute_image.gitlab.image_id
  size     = var.compute_disk["size"]

  lifecycle {
    ignore_changes = [image_id]
  }
}

# Создание VM для GitLab Runner
resource "yandex_compute_instance" "gitlab" {
  name        = var.compute_instance["name"]
  zone        = var.zone
  platform_id = var.compute_instance["platform_id"]

  resources {
    cores  = var.compute_instance["cores"]
    memory = var.compute_instance["memory"]
  }

  boot_disk {
    disk_id = yandex_compute_disk.gitlab.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.gitlab.id
    nat       = true
  }

  metadata = {
    ssh-keys  = "ubuntu:${var.compute_instance["ssh_key"]}"
    user-data = "#cloud-config\ntimezone: 'Europe/Moscow'\nruncmd:\n  - curl -L 'https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh' | bash\n  - apt-get -y install gitlab-runner"
  }
}

# Создание экземпляра Gitlab
resource "yandex_gitlab_instance" "demo" {
  name                      = var.gitlab["name"]
  description               = var.gitlab["description"]
  resource_preset_id        = var.gitlab["resource_preset_id"]
  disk_size                 = var.gitlab["disk_size"]
  admin_login               = var.gitlab["admin_login"]
  admin_email               = var.gitlab["admin_email"]
  domain                    = var.gitlab["domain"]
  approval_rules_id         = var.gitlab["approval_rules_id"]
  backup_retain_period_days = var.gitlab["backup_retain_period_days"]
  subnet_id                 = yandex_vpc_subnet.gitlab.id
}

# Создание сервиса для хранения и распространения Docker-образов 
resource "yandex_container_registry" "gitlab" {
  name      = var.registry["name"]
  folder_id = var.folder_id
}

# Даем сервисному аккаунту право "пуллить" образы
resource "yandex_container_registry_iam_binding" "puller" {
  registry_id = yandex_container_registry.gitlab.id
  role        = "container-registry.images.puller"

  members = [
    "serviceAccount:${yandex_iam_service_account.gitlab.id}"
  ]
}

# Даем сервисному аккаунту право "пушить" образы
resource "yandex_container_registry_iam_binding" "pusher" {
  registry_id = yandex_container_registry.gitlab.id
  role        = "container-registry.images.pusher"

  members = [
    "serviceAccount:${yandex_iam_service_account.gitlab.id}"
  ]
}

# Ключ Yandex Key Management Service для шифрования секретов в Lockbox
resource "yandex_kms_symmetric_key" "gitlab" {
  name              = var.kms_key_name
  default_algorithm = "AES_256"
  rotation_period   = "8760h" # 1 год.
}

# Создание сервиса для хранения секретов
resource "yandex_lockbox_secret" "gitlab" {
  folder_id = var.folder_id
  name = var.lockbox["name"]
  deletion_protection = true
  kms_key_id = yandex_kms_symmetric_key.gitlab.id
}

# Даем сервисному аккаунту право на просмотр секретов
resource "yandex_lockbox_secret_iam_binding" "payloadViewer" {
  secret_id = yandex_lockbox_secret.gitlab.id
  role      = "lockbox.payloadViewer"

  members = [
    "serviceAccount:${yandex_iam_service_account.gitlab.id}"
  ]
}
