# Terraform configuration for deploying Educational App to Cloud Run
# This creates serverless containers that auto-scale and deploy from GitHub

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
  ])
  
  service            = each.value
  disable_on_destroy = false
}

# Artifact Registry for Docker images
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "educational-app"
  description   = "Docker repository for educational app microservices"
  format        = "DOCKER"
  
  depends_on = [google_project_service.required_apis]
}

# MongoDB Atlas or Cloud SQL can be added here
# For now, we'll use environment variables to connect to external MongoDB

# Auth Service - Cloud Run
resource "google_cloud_run_v2_service" "auth_service" {
  name     = "auth-service"
  location = var.region
  
  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/educational-app/auth-service:latest"
      
      ports {
        container_port = 3001
      }
      
      env {
        name  = "PORT"
        value = "3001"
      }
      
      env {
        name  = "MONGODB_URI"
        value = var.mongodb_uri
      }
      
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
    
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
  }
  
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
  
  depends_on = [google_project_service.required_apis]
}

# Learning Service - Cloud Run
resource "google_cloud_run_v2_service" "learning_service" {
  name     = "learning-service"
  location = var.region
  
  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/educational-app/learning-service:latest"
      
      ports {
        container_port = 3002
      }
      
      env {
        name  = "PORT"
        value = "3002"
      }
      
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
    
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
  }
  
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
  
  depends_on = [google_project_service.required_apis]
}

# Payment Service - Cloud Run
resource "google_cloud_run_v2_service" "payment_service" {
  name     = "payment-service"
  location = var.region
  
  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/educational-app/payment-service:latest"
      
      ports {
        container_port = 3003
      }
      
      env {
        name  = "PORT"
        value = "3003"
      }
      
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
    
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
  }
  
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
  
  depends_on = [google_project_service.required_apis]
}

# API Gateway - Cloud Run
resource "google_cloud_run_v2_service" "api_gateway" {
  name     = "api-gateway"
  location = var.region
  
  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/educational-app/api-gateway:latest"
      
      ports {
        container_port = 8000
      }
      
      env {
        name  = "PORT"
        value = "8000"
      }
      
      env {
        name  = "AUTH_SERVICE_URL"
        value = google_cloud_run_v2_service.auth_service.uri
      }
      
      env {
        name  = "LEARNING_SERVICE_URL"
        value = google_cloud_run_v2_service.learning_service.uri
      }
      
      env {
        name  = "PAYMENT_SERVICE_URL"
        value = google_cloud_run_v2_service.payment_service.uri
      }
      
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
    
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
  }
  
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
  
  depends_on = [
    google_cloud_run_v2_service.auth_service,
    google_cloud_run_v2_service.learning_service,
    google_cloud_run_v2_service.payment_service
  ]
}

# Frontend - Cloud Run
resource "google_cloud_run_v2_service" "frontend" {
  name     = "frontend"
  location = var.region
  
  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/educational-app/frontend:latest"
      
      ports {
        container_port = 80
      }
      
      env {
        name  = "VITE_API_URL"
        value = google_cloud_run_v2_service.api_gateway.uri
      }
      
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
    
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
  }
  
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
  
  depends_on = [google_cloud_run_v2_service.api_gateway]
}

# Allow public access to services
resource "google_cloud_run_v2_service_iam_member" "auth_public" {
  name     = google_cloud_run_v2_service.auth_service.name
  location = google_cloud_run_v2_service.auth_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "learning_public" {
  name     = google_cloud_run_v2_service.learning_service.name
  location = google_cloud_run_v2_service.learning_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "payment_public" {
  name     = google_cloud_run_v2_service.payment_service.name
  location = google_cloud_run_v2_service.payment_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "gateway_public" {
  name     = google_cloud_run_v2_service.api_gateway.name
  location = google_cloud_run_v2_service.api_gateway.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "frontend_public" {
  name     = google_cloud_run_v2_service.frontend.name
  location = google_cloud_run_v2_service.frontend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
