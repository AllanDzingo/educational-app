# Terraform configuration for deploying Educational App to GKE
# This creates a Kubernetes cluster and deploys your existing K8s manifests

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
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
    "container.googleapis.com",
    "compute.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
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

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Network configuration
  network    = "default"
  subnetwork = "default"
  
  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Autopilot mode (optional - simpler management)
  # Uncomment to use Autopilot instead of standard cluster
  # enable_autopilot = true
  
  depends_on = [google_project_service.required_apis]
}

# Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  
  node_config {
    preemptible  = var.use_preemptible_nodes
    machine_type = var.machine_type
    
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    labels = {
      env = var.environment
    }
    
    tags = ["gke-node", "${var.cluster_name}-node"]
    
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
  
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Configure kubectl to connect to the cluster
provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

data "google_client_config" "default" {}

# Create namespace for the app
resource "kubernetes_namespace" "educational_app" {
  metadata {
    name = "educational-app"
  }
  
  depends_on = [google_container_node_pool.primary_nodes]
}

# MongoDB deployment (using your existing manifest)
resource "kubernetes_deployment" "mongo" {
  metadata {
    name      = "mongo"
    namespace = kubernetes_namespace.educational_app.metadata[0].name
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        app = "mongo"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "mongo"
        }
      }
      
      spec {
        container {
          name  = "mongo"
          image = "mongo:latest"
          
          port {
            container_port = 27017
          }
          
          volume_mount {
            name       = "mongo-storage"
            mount_path = "/data/db"
          }
        }
        
        volume {
          name = "mongo-storage"
          
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mongo_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

# MongoDB Service
resource "kubernetes_service" "mongo" {
  metadata {
    name      = "mongo"
    namespace = kubernetes_namespace.educational_app.metadata[0].name
  }
  
  spec {
    selector = {
      app = "mongo"
    }
    
    port {
      port        = 27017
      target_port = 27017
    }
    
    type = "ClusterIP"
  }
}

# Persistent Volume Claim for MongoDB
resource "kubernetes_persistent_volume_claim" "mongo_pvc" {
  metadata {
    name      = "mongo-pvc"
    namespace = kubernetes_namespace.educational_app.metadata[0].name
  }
  
  spec {
    access_modes = ["ReadWriteOnce"]
    
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

# Auth Service Deployment
resource "kubernetes_deployment" "auth_service" {
  metadata {
    name      = "auth-service"
    namespace = kubernetes_namespace.educational_app.metadata[0].name
  }
  
  spec {
    replicas = 2
    
    selector {
      match_labels = {
        app = "auth-service"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "auth-service"
        }
      }
      
      spec {
        container {
          name  = "auth-service"
          image = "${var.region}-docker.pkg.dev/${var.project_id}/educational-app/auth-service:latest"
          
          port {
            container_port = 3001
          }
          
          env {
            name  = "PORT"
            value = "3001"
          }
          
          env {
            name  = "MONGODB_URI"
            value = "mongodb://mongo:27017/educational-app"
          }
        }
      }
    }
  }
  
  depends_on = [kubernetes_service.mongo]
}

# Auth Service
resource "kubernetes_service" "auth_service" {
  metadata {
    name      = "auth-service"
    namespace = kubernetes_namespace.educational_app.metadata[0].name
  }
  
  spec {
    selector = {
      app = "auth-service"
    }
    
    port {
      port        = 3001
      target_port = 3001
    }
    
    type = "ClusterIP"
  }
}

# Learning Service Deployment
resource "kubernetes_deployment" "learning_service" {
  metadata {
    name      = "learning-service"
    namespace = kubernetes_namespace.educational_app.metadata[0].name
  }
  
  spec {
    replicas = 2
    
    selector {
      match_labels = {
        app = "learning-service"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "learning-service"
        }
      }
      
      spec {
        container {
          name  = "learning-service"
          image = "${var.region}-docker.pkg.dev/${var.project_id}/educational-app/learning-service:latest"
          
          port {
            container_port = 3002
          }
          
          env {
            name  = "PORT"
            value = "3002"
          }
        }
      }
    }
  }
}

# Learning Service
resource "kubernetes_service" "learning_service" {
  metadata {
    name      = "learning-service"
    namespace = kubernetes_namespace.educational_app.metadata[0].name
  }
  
  spec {
    selector = {
      app = "learning-service"
    }
    
    port {
      port        = 3002
      target_port = 3002
    }
    
    type = "ClusterIP"
  }
}

# Payment Service Deployment
resource "kubernetes_deployment" "payment_service" {
  metadata {
    name      = "payment-service"
    namespace = kubernetes_namespace.educational_app.metadata[0].name
  }
  
  spec {
    replicas = 2
    
    selector {
      match_labels = {
        app = "payment-service"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "payment-service"
        }
      }
      
      spec {
        container {
          name  = "payment-service"
          image = "${var.region}-docker.pkg.dev/${var.project_id}/educational-app/payment-service:latest"
          
          port {
            container_port = 3003
          }
          
          env {
            name  = "PORT"
            value = "3003"
          }
        }
      }
    }
  }
}

# Payment Service
resource "kubernetes_service" "payment_service" {
  metadata {
    name      = "payment-service"
    namespace = kubernetes_namespace.educational_app.metadata[0].name
  }
  
  spec {
    selector = {
      app = "payment-service"
    }
    
    port {
      port        = 3003
      target_port = 3003
    }
    
    type = "ClusterIP"
  }
}

# API Gateway Deployment
resource "kubernetes_deployment" "api_gateway" {
  metadata {
    name      = "api-gateway"
    namespace = kubernetes_namespace.educational_app.metadata[0].name
  }
  
  spec {
    replicas = 2
    
    selector {
      match_labels = {
        app = "api-gateway"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "api-gateway"
        }
      }
      
      spec {
        container {
          name  = "api-gateway"
          image = "${var.region}-docker.pkg.dev/${var.project_id}/educational-app/api-gateway:latest"
          
          port {
            container_port = 8000
          }
          
          env {
            name  = "PORT"
            value = "8000"
          }
          
          env {
            name  = "AUTH_SERVICE_URL"
            value = "http://auth-service:3001"
          }
          
          env {
            name  = "LEARNING_SERVICE_URL"
            value = "http://learning-service:3002"
          }
          
          env {
            name  = "PAYMENT_SERVICE_URL"
            value = "http://payment-service:3003"
          }
        }
      }
    }
  }
  
  depends_on = [
    kubernetes_service.auth_service,
    kubernetes_service.learning_service,
    kubernetes_service.payment_service
  ]
}

# API Gateway Service (LoadBalancer)
resource "kubernetes_service" "api_gateway" {
  metadata {
    name      = "api-gateway"
    namespace = kubernetes_namespace.educational_app.metadata[0].name
  }
  
  spec {
    selector = {
      app = "api-gateway"
    }
    
    port {
      port        = 8000
      target_port = 8000
    }
    
    type = "LoadBalancer"
  }
}

# Frontend Deployment
resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.educational_app.metadata[0].name
  }
  
  spec {
    replicas = 2
    
    selector {
      match_labels = {
        app = "frontend"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }
      
      spec {
        container {
          name  = "frontend"
          image = "${var.region}-docker.pkg.dev/${var.project_id}/educational-app/frontend:latest"
          
          port {
            container_port = 80
          }
          
          env {
            name  = "VITE_API_URL"
            value = "http://${kubernetes_service.api_gateway.status[0].load_balancer[0].ingress[0].ip}:8000"
          }
        }
      }
    }
  }
  
  depends_on = [kubernetes_service.api_gateway]
}

# Frontend Service (LoadBalancer)
resource "kubernetes_service" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.educational_app.metadata[0].name
  }
  
  spec {
    selector = {
      app = "frontend"
    }
    
    port {
      port        = 80
      target_port = 80
    }
    
    type = "LoadBalancer"
  }
}
