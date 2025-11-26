# Educational App Project

## Project Overview

This project is a modern educational platform designed to provide interactive learning, user authentication, payment handling, and course management. The application consists of multiple microservices, a frontend portal, and an API Gateway to orchestrate communication between services. The project is a full-stack, cloud-ready solution that demonstrates **DevOps practices, containerization, and infrastructure as code (IaC)**.

### Why We Built This

The purpose of this project is threefold:

1. **Learning by Doing:** As a DevOps learner, building this project helped in understanding how microservices, CI/CD pipelines, and cloud deployment work in practice.
2. **Modern Architecture:** By separating the app into services (Auth, Learning, Payments, API Gateway), we created a scalable, maintainable, and testable architecture.
3. **Hands-on DevOps Skills:** Docker, Kubernetes, Terraform, and Cloud Run were all integrated to simulate real-world deployment workflows and automate infrastructure management.

---

## Project Architecture

```
Frontend (React + TypeScript)
│
▼
API Gateway (Node.js + Express)
│
├──────────► Auth Service (Node.js)
├──────────► Learning Service (Node.js)
└──────────► Payment Service (Node.js)
```

- **Frontend:** Built in React with TypeScript, provides user interfaces for login, signup, dashboards, and course interaction.
- **API Gateway:** Centralizes requests to the microservices, enabling route management, error handling, and service orchestration.
- **Microservices:** Each service is independently deployable and handles a distinct domain (Auth, Learning, Payments).
- **Docker:** All services and frontend are containerized for consistent deployment across environments.
- **Kubernetes:** K8s manifests available for local testing with Minikube or deployment to GKE.
- **Cloud Run:** Serverless deployment option for production with automatic scaling.
- **Terraform:** Infrastructure as Code for automated provisioning on Google Cloud Platform.

---

## Quick Start

### Local Development with Docker Compose

```bash
# Clone the repository
git clone https://github.com/AllanDzingo/educational-app
cd educational-app

# Start all services
docker-compose up --build

# Access the application
# Frontend: http://localhost:5173
# API Gateway: http://localhost:8000
```

### Deploy to Google Cloud Run (Production)

**Option 1: Automated Script (Easiest)**
```powershell
.\deploy-cloud-run.ps1 -ProjectId "your-gcp-project-id" -MongoDbUri "mongodb+srv://..."
```

**Option 2: Manual Terraform Deployment**
```bash
cd terraform/cloud-run
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

📖 **Full Guide**: See [QUICKSTART.md](QUICKSTART.md) for detailed instructions.

### Set Up CI/CD Pipeline (Automated Deployments)

**Automated deployment with Test and Production environments:**
```powershell
.\setup-cicd.ps1 `
    -ProjectId "your-gcp-project-id" `
    -MongoDbUriTest "mongodb+srv://...test..." `
    -MongoDbUriProd "mongodb+srv://...prod..."
```

This sets up:
- ✅ Automatic deployment on push to GitHub
- ✅ Separate Test and Production environments
- ✅ Automated health checks with Postman/Newman
- ✅ Integration tests before production deployment
- ✅ Canary deployment (10% → 100% traffic shift)

📖 **Full CI/CD Guide**: See [CI-CD-GUIDE.md](CI-CD-GUIDE.md) for complete pipeline documentation.


---

## Deployment Options

### 🚀 Cloud Run (Recommended)
- **Serverless** - No infrastructure management
- **Auto-scaling** - Scales to zero when idle
- **Cost-effective** - Pay only for requests (~$5-20/month)
- **Simple** - Deploy from GitHub automatically

📖 **Guide**: [terraform/cloud-run/README.md](terraform/cloud-run/README.md)

### ☸️ Google Kubernetes Engine (GKE)
- **Full control** - Complete Kubernetes features
- **Production-ready** - Advanced orchestration
- **Higher cost** - ~$70-100/month for small cluster

📖 **Guide**: [terraform/gke/README.md](terraform/gke/README.md)

### 🐳 Local Development
- **Docker Compose** - Quick local testing
- **Minikube** - Local Kubernetes cluster

---

## Key Features

1. **User Authentication:** Secure signup and login via the Auth service.
2. **Learning Management:** Courses and content handled by the Learning service.
3. **Payments:** Transactions are handled safely and independently.
4. **API Gateway Routing:** Centralized routing for microservices and error handling.
5. **DevOps Pipeline:** Dockerized services, CI/CD ready, deployable on Cloud Run or Kubernetes.
6. **IaC Ready:** Terraform configurations for Google Cloud Platform deployment.

---

## What We Learned as DevOps Learners

- **Microservices Communication:** Learned to orchestrate multiple Node.js services via an API Gateway.
- **Dockerization:** Each service, including the frontend, was containerized for environment consistency.
- **Kubernetes:** Created K8s manifests and tested deployments locally with Minikube.
- **Cloud Deployment:** Deployed to Google Cloud Run with Terraform for serverless architecture.
- **Infrastructure as Code:** Created reusable Terraform configurations for both Cloud Run and GKE.
- **TypeScript Troubleshooting:** Learned to fix TS compiler errors and when to switch to JavaScript for faster iteration.
- **Frontend Integration:** Learned to structure a React app with proper routing, components, and service calls.
- **Cross-Service Testing:** Validated services with Docker networking to ensure correct endpoints and API responses.

---

## Troubleshooting Steps Taken

1. **TypeScript Compilation Errors:**  
   - Fixed errors like `'React' is declared but its value is never read` by updating imports or removing unused ones.  
   - Resolved implicit `any` types in API Gateway handlers by explicitly typing `req` and `res`.

2. **Docker Build Failures:**  
   - Fixed `npm run build` errors by installing missing dependencies like `axios` and `react-router-dom`.  
   - Ensured proper working directories in Dockerfiles.

3. **PowerShell Path Issues:**  
   - Wrapped file paths in double quotes to handle spaces, e.g., `"C:\Users\Hanco Sipsma\Desktop\Allan 2025\Educational app\terraform"`.

4. **API Gateway Issues:**  
   - Configured correct ports and ensured services were reachable (3001, 3002, 3003 for services, 8000 for gateway).  
   - Switched from TypeScript to JavaScript for faster debugging when TypeScript configs conflicted.

5. **Cloud Deployment:**  
   - Created Terraform configurations for both Cloud Run and GKE.
   - Set up automated deployment pipeline with Cloud Build.
   - Configured service-to-service communication in Cloud Run.

---

## Project Structure

```
educational-app/
├── auth-service/          # Authentication microservice
├── learning-service/      # Learning content microservice
├── payment-service/       # Payment processing microservice
├── api-gateway/           # API Gateway (TypeScript/JavaScript)
├── frontend/              # React frontend
├── k8s/                   # Kubernetes manifests
├── terraform/             # Infrastructure as Code
│   ├── cloud-run/         # Cloud Run deployment
│   └── gke/               # GKE deployment
├── docker-compose.yml     # Local development setup
├── cloudbuild.yaml        # CI/CD configuration
├── deploy-cloud-run.ps1   # Automated deployment script
├── DEPLOYMENT.md          # Deployment guide
└── QUICKSTART.md          # Quick start guide
```

---

## Next Steps / Future Enhancements

- Complete the frontend with fully functional Signup, Login, and Dashboard.
- Integrate MongoDB Atlas for persistent storage in production.
- Set up CI/CD pipeline with Cloud Build for automatic deployments from GitHub.
- Configure monitoring and logging with Cloud Monitoring and Cloud Logging.
- Add security best practices: HTTPS (automatic with Cloud Run), JWT auth, and API rate limiting.
- Implement caching layer with Redis for improved performance.
- Add comprehensive testing (unit, integration, e2e).

---

## Conclusion

This project demonstrates a comprehensive DevOps workflow by combining microservices architecture, Dockerization, Kubernetes orchestration, and Infrastructure as Code. Along the way, we faced real-world challenges in TypeScript, Docker, Cloud deployment, and CI/CD pipelines and learned practical troubleshooting techniques.

It serves as a portfolio-grade project to showcase DevOps skills and understanding of modern software deployment practices, including serverless architectures and cloud-native development.

**Author**: Allan Davies Dzingo  
**Date**: 2025  
**Repository**: https://github.com/AllanDzingo/educational-app

---

## License

MIT License - See LICENSE file for details