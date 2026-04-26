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

variable "sa_name" {
  type        = string
  description = "Наименование сервисного аккаунта, от имени которого Gitlab выполняет действия"
}

variable "vpc" {
  type = object({
    name = string
  })
  description = "Настройки сети, в которой будет запущен Gitlab"
}

variable "vpc_subnet" {
  type = object({
    name           = string
    v4_cidr_blocks = list(string)
  })
  description = "Настройки подсети, в которой будет запущен Gitlab"
}

variable "compute_disk" {
  type = object({
    name = string
    size = number
  })
  description = "Настройки загрузочного диска для ВМ, на которой будет запущен Gitlab Runner"
}

variable "compute_instance" {
  type = object({
    name        = string
    platform_id = string
    cores       = number
    memory      = number
    ssh_key     = string
  })
  description = "Настройки ВМ, на которой будет запущен Gitlab Runner"
}

variable "gitlab" {
  type = object({
    name                      = string
    description               = string
    domain                    = string
    admin_login               = string
    admin_email               = string
    resource_preset_id        = string
    approval_rules_id         = string
    disk_size                 = number
    backup_retain_period_days = number
  })
  description = "Настройки Gitlab"
}
