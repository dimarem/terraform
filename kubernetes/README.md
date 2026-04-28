# Kubernetes

Пример создания кластера Kubernetes.

## Создать ресурсы

> ❗Требуется версия terraform 1.11+.

> ❗Для хранения состояния используется S3. Имя бакета необходимо изменить на свое (см. versions.tf). Инструкции по созданию и управлению бакетом см. в этом [репозитории](https://github.com/dimarem/terraform/tree/main/s3).

1. В текущей директории создать файл `terraform.tfvars` со следующим содержанием:

```
cloud_id  = "<your_cloud_id>"  # ID облака
folder_id = "<your_folder_id>" # ID директории в облаке
zone      = "ru-central1-a"    # зона доступности
vpc = {                        # настройки сети, в которой будет запущен Kubernetes
  name = "demo-kube-vpc"
}
vpc_subnet = {                 # настройки подсети, в которой будет запущен Kubernetes
  name           = "demo-kube-vpc-subnet"
  v4_cidr_blocks = ["10.5.0.0/24"]
}
service_account_name = "kube-sa"  # наименование сервисного аккаунта, который будет управлять кластером Kubernetes
kms_key_name         = "kube-kms" # наименование ключа шифрования
cluster = {
  name                    = "demo-kube"  # наименование кластера
  kubernetes_version      = "1.33"       # версия Kubernetes
  min_resource_preset_id  = "s-c4-m16"   # идентификатор набора вычислительных ресурсов (4 ядра, 16Гб RAM)
  network_policy_provider = "CALICO"     # наименование сетевого плагина
  node_group = {
    platform_id             = "standard-v2"           # тип платформы ВМ в группе узлов
    admin_name              = "<your_admin_name>"     # имя администратора ВМ в группе узлов
    ssh_pub_key             = "<your_ssh_public_key>" # публичный ключ администратора
    boot_disk_type          = "network-ssd"           # тип загрузочного диска
    boot_disk_size          = 64                      # размер загрузочного диска в Гб
    node_num                = 2                       # количество узлов в кластере
    memory                  = 16                      # объем памяти в Гб на одном узле
    cores                   = 4                       # количество ядер на одном узле
  }
}
```

cloud_id, folder_id, admin_name и ssh_pub_key указать свои.

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

## Получить пресеты вычислительных ресурсов

```bash
yc managed-kubernetes resource-preset list
```

## Удалить ресурсы

```bash
terraform destroy
```

## Документация

- [yandex_kubernetes_cluster](https://yandex.cloud/ru/docs/terraform/resources/kubernetes_cluster)
- [yandex_iam_service_account](https://yandex.cloud/ru/docs/terraform/resources/iam_service_account)
- [yandex_resourcemanager_folder_iam_member](https://yandex.cloud/ru/docs/terraform/resources/resourcemanager_folder_iam_member)
- [yandex_kms_symmetric_key](https://yandex.cloud/ru/docs/terraform/resources/kms_symmetric_key)
- [yandex_kubernetes_node_group](https://yandex.cloud/ru/docs/terraform/resources/kubernetes_node_group)
- [yandex_vpc_network](https://yandex.cloud/ru/docs/terraform/resources/vpc_network)
- [yandex_vpc_subnet](https://yandex.cloud/ru/docs/terraform/resources/vpc_subnet)
- [resource-preset list](https://yandex.cloud/ru/docs/managed-kubernetes/cli-ref/resource-preset/list)
- [platform id list](https://yandex.cloud/ru/docs/compute/concepts/vm-platforms)
- [disks](https://yandex.cloud/ru/docs/compute/concepts/disk)
- [random](https://registry.terraform.io/providers/hashicorp/random/latest/docs)
