output "service_name" {
  value = kubernetes_service.service.metadata.0.name
}
output "service_port" {
  value = kubernetes_service.service.spec.0.port.0.port
}
output "service_target_port" {
  value = kubernetes_service.service.spec.0.port.0.target_port
}
output "service_healthcheck_path" {
  value = kubernetes_deployment.deployment.spec.0.template.0.spec.0.container.0.liveness_probe.0.http_get.0.path
}