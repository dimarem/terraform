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
  description = "Наименование сервисного аккаунта, от имени которого создается бакет"
}

variable "kms_name" {
  type        = string
  description = "Наименование kms-ключа"
}

variable "bucket_name" {
  type        = string
  description = "Наименование бакета"
}

variable "bucket_max_size" {
  type        = number
  default     = 1073741824
  description = "Максимальный размер бакета в байтах"
}

variable "bucket_storage_cls" {
  type        = string
  default     = "STANDARD"
  description = "Класс хранилища"

  validation {
    condition     = contains(["STANDARD", "COLD", "ICE"], var.bucket_storage_cls)
    error_message = "Недопустимое значение зоны"
  }
}

variable "bucket_versioning" {
  type        = bool
  default     = true
  description = "Версионирование объектов в бакете"
}
