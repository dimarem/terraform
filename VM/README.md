# Виртуальная машина (VM)

Пример создания виртуальной машины.

## Создать ресурсы

> ❗Требуется версия terraform 1.11+.

> ❗Для хранения состояния используется S3. Имя бакета необходимо изменить на свое (см. versions.tf). Инструкции по созданию и управлению бакетом см. в этом [репозитории](https://github.com/dimarem/terraform/tree/main/s3).

1. В текущей директории создать файл `terraform.tfvars` со следующим содержанием:

```
cloud_id  = "<your_cloud_id>"
folder_id = "<your_folder_id>"
zone      = "ru-central1-a"
vpc = {
  name = "demo-ci-vpc"
}
vpc_subnet = {
  name           = "demo-ci-vpc-subnet"
  v4_cidr_blocks = ["10.5.0.0/24"]
}
cd = {
  name = "demo-cd"
  type = "network-ssd"
  size = 15
  nat = true
}
ci = {
  name        = "demo-ci"
  platform_id = "standard-v3"
  cores       = 4
  memory      = 8
  nat         = true
}
cloud_init = {
  admin_name  = "<your_admin_name>"
  ssh_pub_key = "<your_ssh_public_key>"
}
```

cloud_id, folder_id и cloud_init указать свои.

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
terraform plan -out=.tfplan
```

5. Применить манифесты:

```bash
terraform apply .tfplan
```

## Подключение по ssh

```bash
ssh <your_admin_name>@<vm_public_ip>
# или
ssh -i ~/.ssh/<your_ssh_public_key> <your_admin_name>@<vm_public_ip>
```

## Получить список образов

```bash
yc compute image list --folder-id standard-images
```

## Удалить ресурсы

```bash
terraform destroy
```

## Документация

- [yandex_compute_instance](https://yandex.cloud/ru/docs/terraform/resources/compute_instance)
- [yandex_compute_disk](https://yandex.cloud/ru/docs/terraform/resources/compute_disk)
- [yandex_vpc_network](https://yandex.cloud/ru/docs/terraform/resources/vpc_network)
- [yandex_vpc_subnet](https://yandex.cloud/ru/docs/terraform/resources/vpc_subnet)
- [yandex_compute_image](https://yandex.cloud/ru/docs/terraform/data-sources/compute_image)
- [random](https://registry.terraform.io/providers/hashicorp/random/latest/docs)
- [Получить список публичных образов](https://yandex.cloud/ru/docs/compute/operations/images-with-pre-installed-software/get-list)
