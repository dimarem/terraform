# Создание сервисного аккаунта
resource "yandex_iam_service_account" "demo_bucket_sa" {
  name = "${var.sa_name}-${random_string.suffix.result}"
}

# Назначение ролей сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "storage_admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.demo_bucket_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "kms_keys_encrypter" {
  folder_id = var.folder_id
  role      = "kms.keys.encrypter"
  member    = "serviceAccount:${yandex_iam_service_account.demo_bucket_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "kms_keys_decrypter" {
  folder_id = var.folder_id
  role      = "kms.keys.decrypter"
  member    = "serviceAccount:${yandex_iam_service_account.demo_bucket_sa.id}"
}

# Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "demo_bucket_sa_key" {
  service_account_id = yandex_iam_service_account.demo_bucket_sa.id
  description        = "Статический ключ для бакета ${var.bucket_name}"
}

# Создание ключа шифрования
resource "yandex_kms_symmetric_key" "demo_bucket_kms_key" {
  name              = "${var.kms_name}--${random_string.suffix.result}"
  description       = "Наименование kms-ключа для бакета ${var.bucket_name}"
  default_algorithm = "AES_256"
  rotation_period   = "8760h" // 1 год
}

# Создание бакета
resource "yandex_storage_bucket" "demo_bucket" {
  access_key            = yandex_iam_service_account_static_access_key.demo_bucket_sa_key.access_key
  secret_key            = yandex_iam_service_account_static_access_key.demo_bucket_sa_key.secret_key
  folder_id             = var.folder_id
  bucket                = "${var.bucket_name}-${random_string.suffix.result}"
  max_size              = var.bucket_max_size
  default_storage_class = var.bucket_storage_cls

  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }

  versioning {
    enabled = var.bucket_versioning
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.demo_bucket_kms_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }

  depends_on = [yandex_resourcemanager_folder_iam_member.storage_admin]
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "null_resource" "save_keys" {
  depends_on = [yandex_iam_service_account_static_access_key.demo_bucket_sa_key]
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "ACCESS_KEY=${yandex_iam_service_account_static_access_key.demo_bucket_sa_key.access_key}" > .keys.txt
      echo "SECRET_KEY=${yandex_iam_service_account_static_access_key.demo_bucket_sa_key.secret_key}" >> .keys.txt
      chmod 600 .keys.txt
    EOT
  }
}
