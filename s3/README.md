# S3 (Simple Storage Service)

Пример создания бакета с версионированием и шифрованием данных в Yandex Cloud S3. Данный бакет можно использовать для хранения состояния terraform'а.

## Создать ресурсы

1. В текущей директории создать файл `terraform.tfvars` со следующим содержанием:

```
cloud_id           = "<your_cloud_id>"
folder_id          = "your_folder_id"
zone               = "ru-central1-a"
sa_name            = "demo-bucket-sa"
kms_name           = "demo-bucket-kms"
bucket_name        = "demo-bucket"
bucket_max_size    = 1073741824 # 1Гб
bucket_storage_cls = "STANDARD"
```

cloud_id и folder_id указать свои.

2. Инициализировать рабочую директорию:

```bash
terraform init
```

3. Проверить конфигурацию (опционально):

```bash
terraform validate
```

4. Вывести план (опционально):

```bash
terraform plan
```

5. Применить манифесты:

```bash
terraform apply
```

ℹ️ После создания ресурсов будет создан файл `.keys.txt`, содержащий `ACCESS_KEY` и `SECRET_KEY`, а также отображены значения переменных `bucket_name` и `service_account_id` для доступа к бакету.

6. Вывести результат (опционально):

```bash
terraform state show yandex_storage_bucket.demo_bucket
```

## Использование бакета

В настройках terraform указать следующее:

```hcl
terraform {
  ...

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    bucket       = "<bucket_name>"
    region       = "ru-central1"
    key          = "terraform.tfstate"
    use_lockfile = true

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
  }
}
```

Создать переменные среды:

```bash
export AWS_ACCESS_KEY_ID="<ACCESS_KEY>"
export AWS_SECRET_ACCESS_KEY="<SECRET_KEY>"
```

❗Требуется версия terraform 1.11+.

## Удалить ресурсы

```bash
terraform destroy
```

## Документация

- [Бакет в Object Storage](https://yandex.cloud/ru/docs/storage/concepts/bucket)
- [Создание бакета](https://yandex.cloud/ru/docs/storage/operations/buckets/create)
- [Версионирование бакета](https://yandex.cloud/ru/docs/storage/concepts/versioning)
- [Шифрование бакета](https://yandex.cloud/ru/docs/storage/operations/buckets/encrypt)
- [yandex_storage_bucket](https://yandex.cloud/ru/docs/terraform/resources/storage_bucket)
- [yandex_kms_symmetric_key](https://yandex.cloud/ru/docs/terraform/resources/kms_symmetric_key)
