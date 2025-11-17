# Educational App Project

## Project Overview

This project is a modern educational platform designed to provide interactive learning, user authentication, payment handling, and course management. The application consists of multiple microservices, a frontend portal, and an API Gateway to orchestrate communication between services. The project is a full-stack, cloud-ready solution that demonstrates **DevOps practices, containerization, and infrastructure as code (IaC)**.

### Why We Built This

The purpose of this project is threefold:

1. **Learning by Doing:** As a DevOps learner, building this project helped in understanding how microservices, CI/CD pipelines, and cloud deployment work in practice.
2. **Modern Architecture:** By separating the app into services (Auth, Learning, Payments, API Gateway), we created a scalable, maintainable, and testable architecture.
3. **Hands-on DevOps Skills:** Docker, Kubernetes, Terraform, and Jenkins were all integrated to simulate real-world deployment workflows and automate infrastructure management.

---

## Project Architecture

Frontend (React + TypeScript)
│
▼
API Gateway (Node.js + Express)
│
├──────────► Auth Service (Node.js)
├──────────► Learning Service (Node.js)
└──────────► Payment Service (Node.js)

- **Frontend:** Built in React with TypeScript, provides user interfaces for login, signup, dashboards, and course interaction.
- **API Gateway:** Centralizes requests to the microservices, enabling route management, error handling, and service orchestration.
- **Microservices:** Each service is independently deployable and handles a distinct domain (Auth, Learning, Payments).
- **Docker:** All services and frontend are containerized for consistent deployment across environments.
- **Kubernetes (Minikube):** Used locally for testing container orchestration and scaling microservices.
- **Jenkins:** Configured for automated builds, Docker image pushes, and deployment orchestration.
- **Terraform:** Planned for provisioning cloud infrastructure (AWS, GCP, or Fly.io) in a repeatable and automated way.

---

## Key Features

1. **User Authentication:** Secure signup and login via the Auth service.
2. **Learning Management:** Courses and content handled by the Learning service.
3. **Payments:** Transactions are handled safely and independently.
4. **API Gateway Routing:** Centralized routing for microservices and error handling.
5. **DevOps Pipeline:** Dockerized services, CI/CD with Jenkins, deployable on Kubernetes clusters.
6. **IaC Ready:** Terraform can provision the cloud environment and network infrastructure.

---

## What We Learned as DevOps Learners

- **Microservices Communication:** Learned to orchestrate multiple Node.js services via an API Gateway.
- **Dockerization:** Each service, including the frontend, was containerized for environment consistency.
- **Kubernetes:** Minikube enabled testing of deployments, services, and scaling locally.
- **CI/CD Pipelines:** Jenkins integration allows automated builds and deployment to Kubernetes.
- **TypeScript Troubleshooting:** Learned to fix TS compiler errors (`React is declared but never used`, `implicit any`), and when to switch to JavaScript for faster iteration.
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

5. **Kubernetes Deployment:**  
   - Verified Minikube cluster was running before attempting deployment.  
   - Applied Kubernetes YAML files after building and tagging Docker images.

---

## How to Run Locally

### Prerequisites:
- Node.js
- npm
- Docker & Docker Compose
- Minikube
- Jenkins (optional, for CI/CD)
- Terraform (optional, for IaC)

### Steps:
1. **Clone repository**
   ```bash
   git clone <repo-url>
   cd <project-folder>
Build Docker Images

docker build -t educationalapp-auth-service ./auth-service
docker build -t educationalapp-learning-service ./learning-service
docker build -t educationalapp-payment-service ./payment-service
docker build -t educationalapp-api-gateway ./api-gateway
docker build -t educationalapp-frontend ./frontend


Run Containers

docker run -p 3001:3001 educationalapp-auth-service
docker run -p 3002:3002 educationalapp-learning-service
docker run -p 3003:3003 educationalapp-payment-service
docker run -p 8000:8000 educationalapp-api-gateway
docker run -p 5173:80 educationalapp-frontend


Access Frontend

Open your browser at http://localhost:5173/

Next Steps / Future Enhancements

Complete the frontend with fully functional Signup, Login, and Dashboard.

Integrate a database (PostgreSQL or MongoDB) for persistent storage.

Fully implement Jenkins CI/CD pipeline to automate Docker builds, pushes, and Kubernetes deployments.

Use Terraform to provision cloud infrastructure and networking for production.

Configure monitoring and logging for microservices in Kubernetes (Prometheus, Grafana, ELK stack).

Add security best practices: HTTPS, JWT auth, and API rate limiting.

Conclusion

This project demonstrates a comprehensive DevOps workflow by combining microservices architecture, Dockerization, Kubernetes orchestration, and Infrastructure as Code. Along the way, we faced real-world challenges in TypeScript, Docker, and CI/CD pipelines and learned practical troubleshooting techniques.

It serves as a portfolio-grade project to showcase DevOps skills and understanding of modern software deployment practices.

Author: Allan Davies Dzingo
Date: 2025