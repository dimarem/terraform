locals {
  suffix          = random_string.suffix.result
  vpc_name        = "${var.vpc["name"]}-${local.suffix}"
  vpc_subnet_name = "${var.vpc_subnet["name"]}-${local.suffix}"
  cluster_name    = "${var.cluster["name"]}-${local.suffix}"
  node_group_name = "${local.cluster_name}-node-group-${local.suffix}"
}

# Создание VPC для Kubernetes
resource "yandex_vpc_network" "k8s" {
  name        = local.vpc_name
  description = "Сеть для Kubernetes ${local.cluster_name}"
}

# Создание подсети для Kubernetes
resource "yandex_vpc_subnet" "k8s" {
  name           = local.vpc_subnet_name
  zone           = var.zone
  network_id     = yandex_vpc_network.k8s.id
  v4_cidr_blocks = var.vpc_subnet["v4_cidr_blocks"]
  description    = "Подсеть для Kubernetes ${local.cluster_name}"
}

# Создание сервисного аккаунта для управления кластером Kubernetes
resource "yandex_iam_service_account" "k8s" {
  name        = var.service_account_name
  description = "Сервисный аккаунт для управления кластером Kubernetes"
}

# Сервисному аккаунту назначается роль 'k8s.clusters.agent'
resource "yandex_resourcemanager_folder_iam_member" "k8s-clusters-agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

# Сервисному аккаунту назначается роль 'alb.editor'
resource "yandex_resourcemanager_folder_iam_member" "alb-editor" {
  folder_id = var.folder_id
  role      = "alb.editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

# Сервисному аккаунту назначается роль 'editor'
resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

# Сервисному аккаунту назначается роль 'vpc.publicAdmin'
resource "yandex_resourcemanager_folder_iam_member" "vpc-publicAdmin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

# Сервисному аккаунту назначается роль 'certificate-manager.certificates.downloader'
resource "yandex_resourcemanager_folder_iam_member" "certificates-downloader" {
  folder_id = var.folder_id
  role      = "certificate-manager.certificates.downloader"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

# Сервисному аккаунту назначается роль 'compute.viewer'
resource "yandex_resourcemanager_folder_iam_member" "compute-viewer" {
  folder_id = var.folder_id
  role      = "compute.viewer"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

# Сервисному аккаунту назначается роль 'container-registry.images.puller'
resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

# Ключ Yandex Key Management Service для шифрования важной информации, такой как пароли, OAuth-токены и SSH-ключи
resource "yandex_kms_symmetric_key" "k8s" {
  name              = var.kms_key_name
  default_algorithm = "AES_256"
  rotation_period   = "8760h" # 1 год.
}

# Создание кластера Kubernetes
resource "yandex_kubernetes_cluster" "k8s-cluster" {
  name        = local.cluster_name
  description = "Демонстрационный кластер Kubernetes"
  network_id  = yandex_vpc_network.k8s.id
  master {
    version   = var.cluster["kubernetes_version"]
    public_ip = true
    master_location {
      zone      = yandex_vpc_subnet.k8s.zone
      subnet_id = yandex_vpc_subnet.k8s.id
    }
    scale_policy {
      auto_scale {
        min_resource_preset_id = var.cluster["min_resource_preset_id"]
      }
    }
  }
  service_account_id      = yandex_iam_service_account.k8s.id
  node_service_account_id = yandex_iam_service_account.k8s.id
  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s-clusters-agent,
    yandex_resourcemanager_folder_iam_member.alb-editor,
    yandex_resourcemanager_folder_iam_member.editor,
    yandex_resourcemanager_folder_iam_member.vpc-publicAdmin,
    yandex_resourcemanager_folder_iam_member.certificates-downloader,
    yandex_resourcemanager_folder_iam_member.compute-viewer,
    yandex_resourcemanager_folder_iam_member.images-puller
  ]
  kms_provider {
    key_id = yandex_kms_symmetric_key.k8s.id
  }
  network_policy_provider = var.cluster["network_policy_provider"]
}

# Создание группы узлов под управлением Kubernetes 
resource "yandex_kubernetes_node_group" "k8s-node-group" {
  name        = local.node_group_name
  cluster_id  = yandex_kubernetes_cluster.k8s-cluster.id
  description = "Демонстрационная группа узлов кластера Kubernetes"
  version     = var.cluster["kubernetes_version"]

  instance_template {
    platform_id = var.cluster["node_group"]["platform_id"]
    network_interface {
      nat        = true
      subnet_ids = [yandex_vpc_subnet.k8s.id]
    }
    resources {
      memory = var.cluster["node_group"]["memory"]
      cores  = var.cluster["node_group"]["cores"]
    }
    boot_disk {
      type = var.cluster["node_group"]["boot_disk_type"]
      size = var.cluster["node_group"]["boot_disk_size"]
    }
    scheduling_policy {
      preemptible = false
    }
    container_runtime {
      type = "containerd"
    }
    metadata = {
      user-data = templatefile("${path.module}/cloud-init.tftpl", {
        admin_name  = var.cluster["node_group"]["admin_name"]
        ssh_pub_key = var.cluster["node_group"]["ssh_pub_key"]
      })
    }
  }
  scale_policy {
    fixed_scale {
      size = var.cluster["node_group"]["node_num"]
    }
  }
  allocation_policy {
    location {
      zone = var.zone
    }
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
