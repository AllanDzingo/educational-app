output "frontend_url" {
  description = "URL of the frontend application"
  value       = google_cloud_run_v2_service.frontend.uri
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = google_cloud_run_v2_service.api_gateway.uri
}

output "auth_service_url" {
  description = "URL of the Auth Service"
  value       = google_cloud_run_v2_service.auth_service.uri
}

output "learning_service_url" {
  description = "URL of the Learning Service"
  value       = google_cloud_run_v2_service.learning_service.uri
}

output "payment_service_url" {
  description = "URL of the Payment Service"
  value       = google_cloud_run_v2_service.payment_service.uri
}

output "artifact_registry" {
  description = "Artifact Registry repository for Docker images"
  value       = google_artifact_registry_repository.docker_repo.name
}
