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

## Документация

- [yandex_gitlab_instance](https://yandex.cloud/ru/docs/terraform/resources/gitlab_instance)
- [yandex_compute_disk](https://yandex.cloud/ru/docs/terraform/resources/compute_disk)
- [yandex_vpc_network](https://yandex.cloud/ru/docs/terraform/resources/vpc_network)
- [yandex_vpc_subnet](https://yandex.cloud/ru/docs/terraform/resources/vpc_subnet)
- [random](https://registry.terraform.io/providers/hashicorp/random/latest/docs)

---

## Пример проекта

Это простой пример управления инфраструктурой с помощью terraform и CI/CD Gitlab.

В данном примере будет выводиться домен, на котором запущен созданный экземпляр Gitlab.

#### Требуемые действия:

1. Создать проект `tf-project`.

2. Зарегистрировать Gitlab Runner:
2.1 Внутри проекта перейти: `Settings → CI/CD → Runners`
2.2 Нажать **New Project Runner**
2.3 Выбрать **Run untagged jobs** (чтобы не привязывать пайплайн к определённому тегу)
2.4 Нажать **Create runner**
2.5 Скопировать полученную строку для регистрации GitLab Runner
2.6 Зарегистрировать GitLab Runner на созданной выше ВМ (yandex_compute_instance.gitlab)

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

- проверим, что GitLab Runner доступен: `Settings → CI/CD → Runners`, раннер должен быть активен

3. Создать переменные окружения:
3.1 Внутри проекта перейти: `Settings → CI/CD → Variables`
3.2 `TF_VAR_cloud_id`: указать id облака
3.3 `TF_VAR_folder_id`: указать id директории в облаке
3.4 `TF_VAR_zone`: зона доступности (например, "ru-central1-a")
3.5 `TF_VAR_gitlab_id`: id экземпляра Gitlab
3.6 `YC_KEY`: содержимое созданного файла `.key.json` (см. local_file.key) с флагом **MASKED**. Для этого:

- убедиться, что `.key.json` заканчивается на `}`, не на пустую строку
- выполнить команду: `cat .key.json | base64 -w 0`
- полученный хеш указать как значение создаваемой переменной

4. Создать в проекте следующие файлы:

**.gitignore:**

```
.terraform.tfstate
.terraform.tfstate.backup
.terraform.tfstate.lock.info
.terraform.lock.hcl
.terraform/
*.tfplan
*.tfvars
*.out
*.log
terraform.tfvars
```

**main.tf:**

```hcl
data "yandex_gitlab_instance" "demo" {
  id = var.gitlab_id
}
```

**outputs.tf:**

```hcl
output "gitlab_domain" {
  value       = data.yandex_gitlab_instance.demo.domain
  description = "Домен, на котором запущен Gitlab"
}
```

**provider.tf:**

```hcl
provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
```

**variables.tf:**

```hcl
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

variable "gitlab_id" {
  type        = string
  description = "ID Gitlab"
}
```

**versions.tf:**

```hcl
terraform {
  required_version = "~> 1.5"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.87.0"
    }
  }
}
```

**.gitlab-ci.yml:**

```yml
stages:
  - lint
  - init
  - validate
  - plan
  - apply

image:
  name: hashicorp/terraform:1.8
  entrypoint: [""]

variables:
  # провайдер Яндекса автоматически прочитает файл по этому пути
  # и предоставит клиенту terraform права на выполнение действий
  # от имени созданного сервисного аккаунта
  YC_SERVICE_ACCOUNT_KEY_FILE: /tmp/sa-key.json

cache:
  key: terraform-cache-${CI_COMMIT_REF_SLUG}
  paths:
    - .terraform/
    - .terraform.lock.hcl

before_script:
  - echo ${YC_KEY} | base64 -d > /tmp/sa-key.json
  - |
    cat <<EOF >> ~/.terraformrc
    provider_installation {
      network_mirror {
        url = "https://terraform-mirror.yandexcloud.net/"
        include = ["registry.terraform.io/*/*"]
      }
      direct {
        exclude = ["registry.terraform.io/*/*"]
      }
    }
    EOF

lint:checkov:
  stage: lint
  image:
    name: bridgecrew/checkov
    entrypoint: [""]
  before_script: []
  script:
    - checkov -d .

lint:tflint:
  stage: lint
  image:
    name: ghcr.io/terraform-linters/tflint
    entrypoint: [""]
  before_script: []
  script:
    - tflint 

init:
  stage: init
  script:
    - terraform init

validate:
  stage: validate
  script:
    - terraform validate

plan:
  stage: plan
  script:
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - tfplan

apply:
  stage: apply
  script:
    - terraform apply -auto-approve tfplan
  when: manual
  only:
    - main
```

Итоговая структура проекта должна иметь следующий вид:

```
.
├── .gitignore
├── .gitlab-ci.yml
├── main.tf
├── outputs.tf
├── provider.tf
├── variables.tf
└── versions.tf
```

5. Перейти в `Build -> Pipelines` и запустить пайплайн в Gitlab.

## Документация

- [tflint](https://github.com/terraform-linters/tflint)
- [checkov](https://www.checkov.io/)
