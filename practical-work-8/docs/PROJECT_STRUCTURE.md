# Complete Project Structure

## Overview

This document describes the complete file structure for Practical Work 8.

```
practical-work-8/
│
├── README.md                           # Main project documentation
├── PROJECT_STRUCTURE.md                # This file
│
├── auth-service/                       # Authentication microservice
│   ├── docs/
│   │   └── PROMPT.md                  # Complete implementation guide
│   ├── src/
│   │   ├── main/
│   │   │   ├── kotlin/
│   │   │   │   └── com/taskmanagement/auth/
│   │   │   │       ├── AuthServiceApplication.kt
│   │   │   │       ├── config/
│   │   │   │       │   ├── SecurityConfig.kt
│   │   │   │       │   ├── RedisConfig.kt
│   │   │   │       │   └── KafkaConfig.kt
│   │   │   │       ├── controller/
│   │   │   │       │   └── AuthController.kt
│   │   │   │       ├── service/
│   │   │   │       │   ├── AuthService.kt
│   │   │   │       │   ├── TokenService.kt
│   │   │   │       │   └── KafkaProducerService.kt
│   │   │   │       ├── repository/
│   │   │   │       │   └── UserRepository.kt
│   │   │   │       ├── entity/
│   │   │   │       │   └── User.kt
│   │   │   │       ├── dto/
│   │   │   │       │   ├── RegisterRequest.kt
│   │   │   │       │   ├── LoginRequest.kt
│   │   │   │       │   ├── LoginResponse.kt
│   │   │   │       │   ├── UserResponse.kt
│   │   │   │       │   └── TokenValidationResponse.kt
│   │   │   │       └── exception/
│   │   │   │           ├── GlobalExceptionHandler.kt
│   │   │   │           ├── UserAlreadyExistsException.kt
│   │   │   │           └── InvalidCredentialsException.kt
│   │   │   └── resources/
│   │   │       ├── application.yml
│   │   │       └── logback-spring.xml
│   │   └── test/
│   │       └── kotlin/
│   │           └── com/taskmanagement/auth/
│   │               ├── service/
│   │               │   ├── AuthServiceTest.kt
│   │               │   └── TokenServiceTest.kt
│   │               └── controller/
│   │                   └── AuthControllerTest.kt
│   ├── helm/
│   │   └── auth-service/
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       └── templates/
│   │           ├── deployment.yaml
│   │           ├── service.yaml
│   │           ├── configmap.yaml
│   │           ├── secret.yaml
│   │           ├── hpa.yaml
│   │           └── servicemonitor.yaml
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   ├── Dockerfile
│   └── README.md
│
├── task-service/                       # Task management microservice
│   ├── docs/
│   │   └── PROMPT.md                  # Complete implementation guide
│   ├── src/
│   │   ├── main/
│   │   │   ├── kotlin/
│   │   │   │   └── com/taskmanagement/task/
│   │   │   │       ├── TaskServiceApplication.kt
│   │   │   │       ├── config/
│   │   │   │       │   ├── KafkaConfig.kt
│   │   │   │       │   ├── AuthClientConfig.kt
│   │   │   │       │   └── CacheConfig.kt
│   │   │   │       ├── controller/
│   │   │   │       │   └── TaskController.kt
│   │   │   │       ├── service/
│   │   │   │       │   ├── TaskService.kt
│   │   │   │       │   ├── AuthClientService.kt
│   │   │   │       │   └── KafkaProducerService.kt
│   │   │   │       ├── repository/
│   │   │   │       │   └── TaskRepository.kt
│   │   │   │       ├── entity/
│   │   │   │       │   ├── Task.kt
│   │   │   │       │   └── TaskStatus.kt
│   │   │   │       ├── dto/
│   │   │   │       │   ├── CreateTaskRequest.kt
│   │   │   │       │   ├── UpdateTaskRequest.kt
│   │   │   │       │   ├── TaskResponse.kt
│   │   │   │       │   ├── TaskPageResponse.kt
│   │   │   │       │   ├── TaskStatsResponse.kt
│   │   │   │       │   └── UserInfo.kt
│   │   │   │       ├── security/
│   │   │   │       │   └── AuthenticationFilter.kt
│   │   │   │       └── exception/
│   │   │   │           ├── GlobalExceptionHandler.kt
│   │   │   │           ├── TaskNotFoundException.kt
│   │   │   │           ├── AccessDeniedException.kt
│   │   │   │           └── UnauthorizedException.kt
│   │   │   └── resources/
│   │   │       ├── application.yml
│   │   │       └── logback-spring.xml
│   │   └── test/
│   │       └── kotlin/
│   │           └── com/taskmanagement/task/
│   │               ├── service/
│   │               │   ├── TaskServiceTest.kt
│   │               │   └── AuthClientServiceTest.kt
│   │               └── controller/
│   │                   └── TaskControllerTest.kt
│   ├── helm/
│   │   └── task-service/
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       └── templates/
│   │           ├── deployment.yaml
│   │           ├── service.yaml
│   │           ├── configmap.yaml
│   │           ├── secret.yaml
│   │           ├── hpa.yaml
│   │           └── servicemonitor.yaml
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   ├── Dockerfile
│   └── README.md
│
├── notification-service/               # Notification microservice
│   ├── docs/
│   │   └── PROMPT.md                  # Complete implementation guide
│   ├── src/
│   │   ├── main/
│   │   │   ├── kotlin/
│   │   │   │   └── com/taskmanagement/notification/
│   │   │   │       ├── NotificationServiceApplication.kt
│   │   │   │       ├── config/
│   │   │   │       │   ├── KafkaConsumerConfig.kt
│   │   │   │       │   └── AuthClientConfig.kt
│   │   │   │       ├── controller/
│   │   │   │       │   └── NotificationController.kt
│   │   │   │       ├── service/
│   │   │   │       │   ├── NotificationService.kt
│   │   │   │       │   ├── KafkaConsumerService.kt
│   │   │   │       │   └── AuthClientService.kt
│   │   │   │       ├── repository/
│   │   │   │       │   └── NotificationRepository.kt
│   │   │   │       ├── entity/
│   │   │   │       │   └── Notification.kt
│   │   │   │       ├── dto/
│   │   │   │       │   ├── NotificationResponse.kt
│   │   │   │       │   ├── NotificationPageResponse.kt
│   │   │   │       │   ├── UnreadCountResponse.kt
│   │   │   │       │   ├── MarkAllReadResponse.kt
│   │   │   │       │   └── KafkaEvent.kt
│   │   │   │       ├── security/
│   │   │   │       │   └── AuthenticationFilter.kt
│   │   │   │       └── exception/
│   │   │   │           ├── GlobalExceptionHandler.kt
│   │   │   │           ├── NotificationNotFoundException.kt
│   │   │   │           └── UnauthorizedException.kt
│   │   │   └── resources/
│   │   │       ├── application.yml
│   │   │       └── logback-spring.xml
│   │   └── test/
│   │       └── kotlin/
│   │           └── com/taskmanagement/notification/
│   │               ├── service/
│   │               │   ├── NotificationServiceTest.kt
│   │               │   └── KafkaConsumerServiceTest.kt
│   │               └── controller/
│   │                   └── NotificationControllerTest.kt
│   ├── helm/
│   │   └── notification-service/
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       └── templates/
│   │           ├── deployment.yaml
│   │           ├── service.yaml
│   │           ├── configmap.yaml
│   │           ├── secret.yaml
│   │           ├── hpa.yaml
│   │           └── servicemonitor.yaml
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   ├── Dockerfile
│   └── README.md
│
├── infrastructure/                     # Infrastructure Helm charts
│   ├── docs/
│   │   ├── PROMPT.md                  # Infrastructure setup guide
│   │   └── ARCHITECTURE.md            # System architecture
│   ├── helm/
│   │   ├── postgresql/
│   │   │   ├── auth-postgres/
│   │   │   │   ├── Chart.yaml
│   │   │   │   ├── values.yaml
│   │   │   │   └── templates/
│   │   │   │       ├── statefulset.yaml
│   │   │   │       ├── service.yaml
│   │   │   │       ├── pvc.yaml
│   │   │   │       ├── configmap.yaml
│   │   │   │       └── secret.yaml
│   │   │   ├── task-postgres/
│   │   │   │   └── (same structure)
│   │   │   └── notification-postgres/
│   │   │       └── (same structure)
│   │   ├── redis/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   └── templates/
│   │   │       ├── deployment.yaml
│   │   │       ├── service.yaml
│   │   │       ├── configmap.yaml
│   │   │       └── secret.yaml
│   │   ├── kafka/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   └── templates/
│   │   │       ├── statefulset.yaml
│   │   │       ├── service.yaml
│   │   │       └── configmap.yaml
│   │   ├── krakend/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   └── templates/
│   │   │       ├── deployment.yaml
│   │   │       ├── service.yaml
│   │   │       ├── configmap.yaml
│   │   │       └── ingress.yaml
│   │   ├── graylog/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   └── templates/
│   │   │       ├── mongodb/
│   │   │       │   ├── statefulset.yaml
│   │   │       │   ├── service.yaml
│   │   │       │   └── secret.yaml
│   │   │       ├── elasticsearch/
│   │   │       │   ├── statefulset.yaml
│   │   │       │   ├── service.yaml
│   │   │       │   └── pvc.yaml
│   │   │       └── graylog/
│   │   │           ├── deployment.yaml
│   │   │           ├── service.yaml
│   │   │           ├── configmap.yaml
│   │   │           └── secret.yaml
│   │   ├── prometheus/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   └── templates/
│   │   │       ├── deployment.yaml
│   │   │       ├── service.yaml
│   │   │       ├── configmap.yaml
│   │   │       └── servicemonitor.yaml
│   │   ├── grafana/
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   └── templates/
│   │   │       ├── deployment.yaml
│   │   │       ├── service.yaml
│   │   │       ├── configmap.yaml
│   │   │       ├── secret.yaml
│   │   │       └── dashboards/
│   │   │           ├── datasource.yaml
│   │   │           └── task-management-dashboard.json
│   │   └── jaeger/
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       └── templates/
│   │           ├── deployment.yaml
│   │           └── service.yaml
│   ├── krakend/
│   │   └── krakend.json               # KrakenD configuration
│   ├── scripts/
│   │   ├── setup-minikube.sh          # Setup Minikube cluster
│   │   ├── install-all.sh             # Install all infrastructure
│   │   ├── uninstall-all.sh           # Remove all infrastructure
│   │   ├── port-forward-all.sh        # Setup port forwarding
│   │   └── test-infrastructure.sh     # Test infrastructure
│   └── README.md
│
├── scripts/                            # Project-wide scripts
│   ├── build-all.sh                   # Build all service images
│   ├── deploy-all.sh                  # Deploy all services
│   ├── test-system.sh                 # End-to-end testing
│   ├── cleanup-all.sh                 # Remove everything
│   └── load-test.sh                   # Load testing for HPA
│
├── docs/                               # Project documentation
│   ├── ARCHITECTURE.md                # System architecture
│   ├── PROJECT_OVERVIEW.md            # Project overview
│   ├── SERVICES_LIST.md               # Complete services list
│   ├── API.md                         # API documentation
│   ├── DEPLOYMENT.md                  # Deployment guide
│   └── TESTING.md                     # Testing guide
│
├── report/                             # Report files
│   ├── ПВКСП_Отчет8_ГрибковАС_ИКБО-16-22.md
│   ├── ПВКСП_Отчет8_ГрибковАС_ИКБО-16-22.docx
│   ├── ПВКСП_Отчет8_ГрибковАС_ИКБО-16-22.pdf
│   └── screenshots/
│       ├── 01-architecture.png
│       ├── 02-minikube-pods.png
│       ├── 03-auth-register.png
│       ├── 04-auth-login.png
│       ├── 05-task-create.png
│       ├── 06-task-list.png
│       ├── 07-notifications.png
│       ├── 08-kafka-topics.png
│       ├── 09-graylog-logs.png
│       ├── 10-prometheus-metrics.png
│       ├── 11-grafana-dashboard.png
│       ├── 12-jaeger-traces.png
│       ├── 13-persistent-volume.png
│       ├── 14-hpa-scaling.png
│       └── 15-krakend-config.png
│
└── task/                               # Original task description
    ├── task.md
    └── theory.md
```

## File Count Summary

### Source Code Files
- **Auth Service**: ~25 Kotlin files
- **Task Service**: ~30 Kotlin files
- **Notification Service**: ~25 Kotlin files
- **Total**: ~80 Kotlin source files

### Configuration Files
- **Helm Charts**: ~60 YAML files
- **Application Configs**: 3 application.yml, 3 logback-spring.xml
- **Build Files**: 3 build.gradle.kts, 3 settings.gradle.kts
- **Dockerfiles**: 3 files
- **KrakenD**: 1 krakend.json
- **Total**: ~75 configuration files

### Documentation Files
- **PROMPT.md**: 4 files (one per service + infrastructure)
- **README.md**: 5 files (main + one per service + infrastructure)
- **Other docs**: 6 files
- **Total**: ~15 documentation files

### Scripts
- **Infrastructure scripts**: 5 files
- **Project scripts**: 5 files
- **Total**: 10 shell scripts

### Test Files
- **Auth Service**: ~10 test files
- **Task Service**: ~12 test files
- **Notification Service**: ~10 test files
- **Total**: ~32 test files

### Report Files
- **Report**: 3 files (md, docx, pdf)
- **Screenshots**: ~15 images
- **Total**: ~18 files

## Grand Total
**~230 files** in the complete project

## Key Files to Focus On

### Must-Read Documentation
1. `README.md` - Start here
2. `docs/ARCHITECTURE.md` - System design
3. `docs/SERVICES_LIST.md` - All services explained
4. `docs/PROJECT_OVERVIEW.md` - Project scope and planning

### Implementation Guides
1. `auth-service/docs/PROMPT.md` - Auth Service implementation
2. `task-service/docs/PROMPT.md` - Task Service implementation
3. `notification-service/docs/PROMPT.md` - Notification Service implementation
4. `infrastructure/docs/PROMPT.md` - Infrastructure setup

### Configuration Files
1. `infrastructure/krakend/krakend.json` - API Gateway routing
2. `**/application.yml` - Service configurations
3. `**/values.yaml` - Helm chart values
4. `**/logback-spring.xml` - Logging configuration

### Deployment Files
1. `infrastructure/scripts/setup-minikube.sh` - Cluster setup
2. `infrastructure/scripts/install-all.sh` - Infrastructure deployment
3. `scripts/deploy-all.sh` - Services deployment
4. `scripts/test-system.sh` - System testing

## Next Steps

1. **Read Documentation**
   - Start with main README.md
   - Read ARCHITECTURE.md
   - Review SERVICES_LIST.md

2. **Setup Infrastructure**
   - Follow infrastructure/docs/PROMPT.md
   - Run setup scripts
   - Verify all pods running

3. **Implement Services**
   - Start with Auth Service
   - Then Task Service
   - Finally Notification Service
   - Follow respective PROMPT.md files

4. **Deploy & Test**
   - Build Docker images
   - Deploy with Helm
   - Run end-to-end tests
   - Collect screenshots

5. **Write Report**
   - Use screenshots
   - Document configuration
   - Answer questions
   - Prepare for defense

## Estimated Effort

- **Infrastructure Setup**: 20-25 hours
- **Service Development**: 30-45 hours
- **Testing & Debugging**: 10-15 hours
- **Documentation & Report**: 10-15 hours
- **Total**: 70-100 hours (2-3 weeks full-time)

## Notes

- All PROMPT.md files contain complete implementation guides
- Each service is independent and can be developed in parallel
- Infrastructure must be deployed before services
- Test each component before moving to the next
- Keep screenshots organized for report
- Document any deviations from the plan

