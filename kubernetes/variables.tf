variable "cloud_id" {
  type        = string
  description = "ID облака"
}

variable "folder_id" {
  type        = string
  description = "ID директории в облаке"
}

variable "zone" {
  type        = string
  default     = "ru-central1-a"
  description = "Зона доступности"

  validation {
    condition     = contains(["ru-central1-a", "ru-central1-b", "ru-central1-d"], var.zone)
    error_message = "Недопустимое значение зоны"
  }
}

variable "vpc" {
  type = object({
    name = string
  })
  description = "Настройки сети, в которой будет запущен Kubernetes"
}

variable "vpc_subnet" {
  type = object({
    name           = string
    v4_cidr_blocks = list(string)
  })
  description = "Настройки подсети, в которой будет запущен Kubernetes"
}

variable "service_account_name" {
  type        = string
  description = "Наименование сервисного аккаунта, который будет управлять кластером Kubernetes"
}

variable "kms_key_name" {
  type        = string
  description = "Наименование ключа шифрования"
}

variable "cluster" {
  type = object({
    name                    = string
    kubernetes_version      = string
    min_resource_preset_id  = string
    network_policy_provider = string
    node_group = object({
      platform_id    = string
      admin_name     = string
      ssh_pub_key    = string
      boot_disk_type = string
      boot_disk_size = number
      node_num       = number
      memory         = number
      cores          = number
    })
  })
  description = "Настройки кластера Kubernetes"
}
