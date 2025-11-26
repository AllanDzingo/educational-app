variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region for resources"
  type        = string
  default     = "us-central1"
}

variable "mongodb_uri" {
  description = "MongoDB connection URI (use MongoDB Atlas or Cloud-hosted MongoDB)"
  type        = string
  sensitive   = true
}

variable "github_repo" {
  description = "GitHub repository in format: owner/repo"
  type        = string
  default     = "AllanDzingo/educational-app"
}
