# Gitlab

Пример создания и использования Gitlab в Yandex Cloud.

## Создать ресурсы

❗Требуется версия terraform 1.11+.

1. В текущей директории создать файл `terraform.tfvars` со следующим содержанием:

```
cloud_id    = "<your_cloud_id>"
folder_id   = "<your_folder_id>"
zone        = "ru-central1-a"
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

## Удалить ресурсы

```bash
terraform destroy
```

## Документация

- [yandex_gitlab_instance](https://yandex.cloud/ru/docs/terraform/resources/gitlab_instance)
