# Gitlab

Пример создания и использования Gitlab в Yandex Cloud.

## Создать ресурсы

> ❗Требуется версия terraform 1.11+.

> ❗Для хранения состояния используется S3. Имя бакета необходимо изменить на свое (см. versions.tf). Инструкции по созданию и управлению бакетом см. в этом [репозитории](https://github.com/dimarem/terraform/tree/main/s3).

1. В текущей директории создать файл `terraform.tfvars` со следующим содержанием:

```
cloud_id  = "<your_cloud_id>"
folder_id = "<your_folder_id>"
zone      = "ru-central1-a"
sa_name   = "demo-gitlab-sa"
vpc = {
  name = "demo-gitlab-vpc"
}
vpc_subnet = {
  name           = "demo-gitlab-vpc-subnet"
  v4_cidr_blocks = ["10.5.0.0/24"]
}
compute_disk = {
  name = "demo-gitlab-runner-disk"
  size = 15
}
compute_instance = {
  name        = "demo-gitlab-runner"
  platform_id = "standard-v3"
  cores       = 2
  memory      = 2
  ssh_keys    = "ubuntu:${file("~/.ssh/<your_ssh>.pub")}"
  user_data   = "#cloud-config\ntimezone: 'Europe/Moscow'\nruncmd:\n  - curl -L 'https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh' | bash\n  - apt-get -y install gitlab-runner"
}
gitlab = {
  name                      = "demo-gitlab-instance"
  domain                    = "<your_subdomain>.gitlab.yandexcloud.net"
  admin_login               = "<your_login>"
  admin_email               = "<your_email>"
  resource_preset_id        = "s2.micro"
  approval_rules_id         = "BASIC"
  disk_size                 = 30
  backup_retain_period_days = 7
}

```

cloud_id, folder_id, ssh_keys, admin_login, admin_email и domain указать свои.

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
