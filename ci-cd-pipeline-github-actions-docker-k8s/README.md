# 🚀 CI/CD Demo: GitHub Actions + Docker + Kubernetes (Minikube)

This project demonstrates a complete CI/CD pipeline using GitHub Actions to build and push a Docker image, and Kubernetes (via Minikube) to deploy and expose the application.

---

## 📦 Project Summary

A hands-on, reproducible DevOps workflow showcasing:

- Automated Docker image builds via GitHub Actions  
- Image publishing to Docker Hub  
- Kubernetes deployment and service exposure on Minikube  
- Screenshot of the deployed app for visual verification

---

## 🔗 GitHub Repository

- **Repo:** [ParaajwalWeeBe/projects](https://github.com/ParaajwalWeeBe/projects)  
- **Branch:** `ci-cd-pipeline-github-actions-docker-k8s`  
- **Workflow File:** `.github/workflows/ci.yml` — builds and pushes Docker image on every push to `main`

---

## 🐳 Docker Image

- **Docker Hub:** [paraajwalweebe/ci-demo](https://hub.docker.com/repository/docker/paraajwalweebe/ci-demo/general)  
- **Tags:**  
  - `latest` — used in Kubernetes deployment  
  - `<short_sha>` — auto-generated per commit for traceability

---

## ⚙️ CI/CD Workflow Results

- **Trigger:** Push to `main` branch  
- **Steps:**  
  - ✅ Checkout code  
  - ✅ Build Docker image  
  - ✅ Push to Docker Hub  
- **Status:** Successful runs visible in the [GitHub Actions tab](https://github.com/ParaajwalWeeBe/projects/actions)

---

## 🖼️ Deployed App Screenshot

Screenshot of the deployed app via Minikube service:

ci-demo-screenshot.png
