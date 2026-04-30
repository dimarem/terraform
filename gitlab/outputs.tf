output "registry_id" {
  value = yandex_container_registry.gitlab.id
  description = "ID сервиса для хранения и распространения Docker-образов "
}
