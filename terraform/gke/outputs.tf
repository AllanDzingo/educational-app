output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "frontend_ip" {
  description = "External IP of the frontend LoadBalancer"
  value       = kubernetes_service.frontend.status[0].load_balancer[0].ingress[0].ip
}

output "api_gateway_ip" {
  description = "External IP of the API Gateway LoadBalancer"
  value       = kubernetes_service.api_gateway.status[0].load_balancer[0].ingress[0].ip
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
}

output "frontend_url" {
  description = "URL to access the frontend"
  value       = "http://${kubernetes_service.frontend.status[0].load_balancer[0].ingress[0].ip}"
}

output "api_gateway_url" {
  description = "URL to access the API Gateway"
  value       = "http://${kubernetes_service.api_gateway.status[0].load_balancer[0].ingress[0].ip}:8000"
}

output "artifact_registry" {
  description = "Artifact Registry repository for Docker images"
  value       = google_artifact_registry_repository.docker_repo.name
}
