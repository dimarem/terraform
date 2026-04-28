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
  description = "Настройки сети, в которой будет запущена виртуальная машина"
}

variable "vpc_subnet" {
  type = object({
    name           = string
    v4_cidr_blocks = list(string)
  })
  description = "Настройки подсети, в которой будет запущена виртуальная машина"
}

variable "cd" {
  type = object({
    name = string
    type = string
    size = number
    nat  = bool
  })
  description = "Настройки загрузочного диска"
}

variable "ci" {
  type = object({
    name        = string
    platform_id = string
    cores       = number
    memory      = number
  })
  description = "Настройки виртуальной машины"
}

variable "cloud_init" {
  type = object({
    admin_name  = string
    ssh_pub_key = string
  })
  description = "Значения переменных для cloud-init"
}
