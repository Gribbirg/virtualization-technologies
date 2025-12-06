# Virtualization Technologies

Course practical works for "Virtualization Technologies and Cloud Service Platforms" (MIREA).

## Overview

This repository contains 8 practical works covering virtualization, containerization, orchestration, and cloud-native technologies.

## Practical Works

| # | Topic | Technologies |
|---|-------|--------------|
| 1 | Virtual Machine Networking | VMware Workstation, Debian, Kali Linux, Bridge networking |
| 2 | Virtual Networks Configuration | VMware virtual networks, Network services |
| 3 | Docker and Dockerfile | Docker, Dockerfile (13 commands), Spring Boot, PostgreSQL, Multi-stage builds |
| 4 | Monitoring Spring Boot Service | Docker Compose, Prometheus, Grafana, Graylog, Zabbix, PostgreSQL |
| 5 | Kubernetes and Minikube | Kubernetes, Minikube, kubectl, Node.js, Deployments |
| 6 | Kubernetes Application Deployment | Kubernetes, StatefulSet, Redis replication, Ingress, ConfigMaps, Secrets |
| 7 | Resource Management in Kubernetes | Requests/Limits, QoS classes, CPU/Memory management, HPA |
| 8 | Microservices with Observability | Spring Boot, Kotlin, Helm, Kafka, KrakenD, Prometheus, Grafana, Graylog, Jaeger |

## Project Structure

```
virtualization-technologies/
├── practical-work-1/          # VM Networking (VMware)
├── practical-work-2/          # Virtual Networks Configuration
├── practical-work-3/          # Docker and Dockerfile
│   ├── task-1-dockerfile-commands/
│   └── task-2-spring-boot-app/
├── practical-work-4/          # Monitoring Spring Boot Service
│   ├── src/                   # Spring Boot application
│   ├── monitoring/            # Prometheus, Grafana configs
│   └── scripts/               # Test and validation scripts
├── practical-work-5/          # Kubernetes Basics
│   ├── server.js              # Node.js HTTP server
│   ├── Dockerfile
│   └── deployment.yaml
├── practical-work-6/          # Kubernetes Application
│   ├── app/
│   │   ├── frontend/          # Node.js journal server
│   │   ├── redis/             # Redis StatefulSet
│   │   └── fileserver/        # NGINX static files
│   └── scripts/
├── practical-work-7/          # Resource Management
│   ├── memory-request-limit*.yaml
│   ├── cpu-request-limit*.yaml
│   └── scripts/
├── practical-work-8/          # Microservices System
│   ├── auth-service/          # Authentication (Kotlin/Spring Boot)
│   ├── task-service/          # Task management (Kotlin/Spring Boot)
│   ├── notification-service/  # Notifications (Kotlin/Spring Boot)
│   ├── infrastructure/        # Helm charts for all infra
│   └── scripts/
└── common/                    # Shared resources (report templates)
```

## Technology Stack

### Virtualization
- VMware Workstation
- Virtual networks (Bridge, NAT, Host-only)

### Containerization
- Docker
- Docker Compose
- Multi-stage builds

### Orchestration
- Kubernetes (Minikube)
- Helm 3
- StatefulSets, Deployments, Services
- Ingress, ConfigMaps, Secrets
- HPA (Horizontal Pod Autoscaler)

### Application Development
- Java 21 / Kotlin 1.9+
- Spring Boot 3.2+
- Node.js
- PostgreSQL 15
- Redis 7
- Apache Kafka (KRaft mode)

### API Gateway
- KrakenD

### Observability
- **Metrics**: Prometheus + Grafana
- **Logging**: Graylog + MongoDB + Elasticsearch
- **Tracing**: Jaeger
- **Infrastructure Monitoring**: Zabbix

## Quick Start

Each practical work has its own README with detailed instructions.

### Practical Work 3 (Docker)
```bash
cd practical-work-3/task-2-spring-boot-app
./test-docker.sh
```

### Practical Work 4 (Monitoring)
```bash
cd practical-work-4
docker-compose up -d --build
./scripts/test-monitoring.sh
```

### Practical Work 5 (Kubernetes Basics)
```bash
cd practical-work-5
minikube start
./test.sh
```

### Practical Work 6 (Kubernetes Application)
```bash
cd practical-work-6
./scripts/setup-environment.sh
./scripts/build-images.sh
./scripts/test.sh
```

### Practical Work 7 (Resource Management)
```bash
cd practical-work-7
./scripts/run-all.sh
```

### Practical Work 8 (Microservices)
```bash
cd practical-work-8
./scripts/deploy-all.sh
./scripts/port-forward.sh
./scripts/test-system.sh
```

## Prerequisites

### Required Software
- Docker / Docker Desktop / Colima
- Minikube
- kubectl
- Helm 3
- Java 21 (for Spring Boot projects)
- Gradle 8.5+
- Node.js (for practical works 5-6)

### System Requirements
- CPU: 4+ cores
- RAM: 8GB+ (16GB recommended for practical work 8)
- Disk: 30GB+ free space

## Reports

Each practical work includes a report in the `report/` directory:
- Format: `ПВКСП_ОтчетN_ГрибковАС_ИКБО-16-22.md/docx/pdf`
- Contains: objectives, implementation details, screenshots, answers to questions

## Author

**Gribkov Alexander Sergeevich**
Group: IKBO-16-22
MIREA - Russian Technological University

## License

Educational project for MIREA course "Virtualization Technologies and Cloud Service Platforms"
