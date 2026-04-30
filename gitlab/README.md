# Gitlab

Пример создания Gitlab в Yandex Cloud.

## Создать ресурсы

> ❗Требуется версия terraform 1.11+.

> ❗Для хранения состояния используется S3. Имя бакета необходимо изменить на свое (см. versions.tf). Инструкции по созданию и управлению бакетом см. в этом [репозитории](https://github.com/dimarem/terraform/tree/main/s3).

1. В текущей директории создать файл `terraform.tfvars` со следующим содержанием:

```
cloud_id     = "<your_cloud_id>"
folder_id    = "<your_folder_id>"
zone         = "ru-central1-a"
sa_name      = "demo-gitlab-sa"
kms_key_name = "gitlab-kms"
vpc = {
  name = "demo-gitlab-vpc"
}
vpc_subnet = {
  name           = "demo-gitlab-vpc-subnet"
  v4_cidr_blocks = ["10.5.0.0/24"]
}
compute_disk = {
  name = "demo-gitlab-runner-disk"
  size = 30
}
compute_instance = {
  name        = "demo-gitlab-runner"
  platform_id = "standard-v3"
  cores       = 2
  memory      = 4
  ssh_key     = "<your_ssh_pub_key>"
}
gitlab = {
  name                      = "demo-gitlab-instance"
  description               = "Демонстрационный экземпляр Gitlab"
  domain                    = "<your_subdomain>.gitlab.yandexcloud.net"
  admin_login               = "<your_login>"
  admin_email               = "<your_email>"
  resource_preset_id        = "s2.micro"
  approval_rules_id         = "BASIC"
  disk_size                 = 30
  backup_retain_period_days = 7
}
registry = {
  name = "demo-registry"
}
lockbox = {
  name = "demo-lockbox"
}
```

cloud_id, folder_id, ssh_key, admin_login, admin_email и domain указать свои.

2. Инициализировать рабочую директорию:

```bash
terraform init
```

3. Проверить конфигурацию (опционально):

```bash
terraform validate
```

4. Создать план:

```bash
terraform plan -out=.tfplan
```

5. Применить манифесты:

```bash
terraform apply .tfplan
```

6. После создания экземпляра Gitlab подтвердить почту и создать пароль.

## Удалить ресурсы

```bash
terraform destroy
```

## Регистрация Gitlab Runner

1. Внутри проекта перейти: `CI/CD → Runners` на панели администратора
2. Нажать **New Project Runner**
3. Выбрать **Run untagged jobs** (чтобы не привязывать пайплайн к определённому тегу)
4. Нажать **Create runner**
5. Скопировать полученную строку для регистрации GitLab Runner
6. Зарегистрировать GitLab Runner на созданной выше ВМ (yandex_compute_instance.gitlab)

```bash
# подключаемся к ВМ
# следует использовать ключ указанный при ее создании (см. ssh_key) 
ssh ubuntu@<публичный_ip>
# переключемся на root
sudo su -
# выполним команду полученную на шаге 2.5
gitlab-runner register  --url https://<your_subdomain>.gitlab.yandexcloud.net  --token <token>
```

В диалоговом меню:

- GitLab instance URL: оставляем по умолчанию (нажимаем Enter)
- name for the runner: оставляем по умолчанию (нажимаем Enter)
- executor: выбираем "docker"
- default Docker image: выбираем "busybox"
- Если все правильно заполнено, должно быть "Runner registered successfully"
- добавим зеркала для Docker (это необязательно, но может помочь в случае блокировок):

```bash
cat <<EOF > /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://mirror.gcr.io",
    "https://daocloud.io",
    "https://dockerhub.timeweb.cloud"
  ]
}
EOF
```

- перезапустим docker:

```bash
systemctl reload docker
```

- проверим, что GitLab Runner доступен: `CI/CD → Runners`, раннер должен быть активен

## Документация

- [yandex_gitlab_instance](https://yandex.cloud/ru/docs/terraform/resources/gitlab_instance)
- [yandex_compute_disk](https://yandex.cloud/ru/docs/terraform/resources/compute_disk)
- [yandex_vpc_network](https://yandex.cloud/ru/docs/terraform/resources/vpc_network)
- [yandex_vpc_subnet](https://yandex.cloud/ru/docs/terraform/resources/vpc_subnet)
- [yandex_container_registry](https://yandex.cloud/ru/docs/terraform/resources/container_registry)
- [yandex_container_registry_iam_binding](https://yandex.cloud/ru/docs/terraform/resources/container_registry_iam_binding)
- [yandex_lockbox_secret](https://yandex.cloud/ru/docs/terraform/resources/lockbox_secret)
- [yandex_lockbox_secret_iam_binding](https://yandex.cloud/ru/docs/terraform/resources/lockbox_secret_iam_binding)
- [Role reference Yandex Cloud](https://yandex.cloud/ru/docs/iam/roles-reference)
- [random](https://registry.terraform.io/providers/hashicorp/random/latest/docs)
