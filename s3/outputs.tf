output "bucket_name" {
  value       = yandex_storage_bucket.demo_bucket.bucket
  description = "Имя созданного S3 бакета."
}

output "service_account_id" {
  value       = yandex_iam_service_account.demo_bucket_sa.id
  description = "ID сервисного аккаунта, который имеет доступ к бакету."
}
