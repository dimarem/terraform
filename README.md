# Terraform

Различные примеры работы с облачным провайдером с помощью terraform.

## Настройка рабочего места

Необходимо выполнить следующие шаги:

1. [Подготовить облако к работе](https://yndx.auth.yandex.cloud/install).
2. [Установить Terraform (CLI)](https://cloud.yandex.ru/ru/docs/tutorials/infrastructure-management/terraform-quickstart#install-terraform).
3. [Установить Yandex Cloud (CLI)](https://cloud.yandex.ru/ru/docs/cli/quickstart#install).
4. [Cоздать профиль](https://cloud.yandex.ru/ru/docs/cli/quickstart#initialize).
5. [Настроить сервисный аккаунт для Terraform](https://cloud.yandex.ru/ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials). Назначить сервисному аккаунту роль `admin`.
6. [Настроить зеркала для провайдера](https://cloud.yandex.ru/ru/docs/tutorials/infrastructure-management/terraform-quickstart#configure-provider).
7. Узнать идентификатор созданного сервисного аккаунта:

```bash
yc iam service-account list
```

8. Создать переменные окружения:

```bash
export YC_TOKEN=$(yc iam create-token --impersonate-service-account-id <идентификатор_сервисного_аккаунта>)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
```
