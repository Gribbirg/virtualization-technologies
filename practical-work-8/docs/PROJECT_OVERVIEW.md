# Project Overview - Task Management Microservices System

## Executive Summary

This document provides a comprehensive overview of the Task Management System - a cloud-native microservices application designed for Practical Work 8. The system demonstrates modern software architecture patterns, container orchestration, and observability practices.

## Project Goals

### Primary Objectives
1. Implement a working microservices architecture with Spring Boot and Kotlin
2. Deploy on Kubernetes (Minikube) using Helm charts
3. Implement comprehensive observability (logging, metrics, tracing)
4. Demonstrate event-driven architecture with Kafka
5. Show data persistence with PostgreSQL and persistent volumes
6. Implement API Gateway pattern with KrakenD

### Educational Outcomes
- Understanding microservices design patterns
- Hands-on experience with Kubernetes and Helm
- Learning observability best practices
- Implementing event-driven architecture
- Database per service pattern
- API Gateway pattern

## System Scope

### In Scope
✅ User authentication and authorization (JWT)  
✅ Task management (CRUD operations)  
✅ Notification system (event-driven)  
✅ API Gateway (KrakenD)  
✅ Message broker (Kafka)  
✅ Centralized logging (Graylog)  
✅ Metrics collection (Prometheus)  
✅ Metrics visualization (Grafana)  
✅ Distributed tracing (Jaeger)  
✅ Persistent storage (PostgreSQL with PVs)  
✅ Horizontal pod autoscaling  
✅ Health probes (liveness, readiness, startup)  

### Out of Scope
❌ User roles and permissions  
❌ Email/SMS notifications  
❌ File attachments  
❌ Task assignments to multiple users  
❌ Task comments  
❌ Real-time WebSocket updates  
❌ Mobile applications  
❌ Production-grade security hardening  
❌ Multi-region deployment  
❌ Disaster recovery  

## Technical Decisions

### Why Kotlin?
- Modern, concise language
- Excellent Spring Boot support
- Null safety built-in
- Data classes reduce boilerplate
- Interoperable with Java ecosystem

### Why Spring Boot?
- Industry-standard framework
- Extensive ecosystem
- Built-in observability (Actuator)
- Easy Kafka integration
- Excellent documentation

### Why Kafka?
- Decouples services
- Reliable message delivery
- Scalable event streaming
- Industry standard for event-driven architecture

### Why KrakenD?
- High performance (written in Go)
- Declarative configuration
- Built-in JWT validation
- Easy Jaeger integration
- Lightweight compared to alternatives

### Why PostgreSQL?
- Reliable RDBMS
- ACID compliance
- Good Kubernetes support
- Prometheus exporter available
- Familiar to most developers

### Why Redis?
- Fast in-memory storage
- Perfect for JWT token storage
- Simple to deploy
- TTL support built-in

### Why Graylog?
- Powerful log search
- GELF protocol support
- Good UI for log analysis
- Elasticsearch-backed storage

### Why Prometheus + Grafana?
- Industry standard for metrics
- Pull-based model works well in Kubernetes
- Rich query language (PromQL)
- Grafana provides excellent visualizations

### Why Jaeger?
- CNCF graduated project
- Easy integration
- Good UI for trace analysis
- All-in-one mode for simplicity

## Service Breakdown

### Auth Service (Critical Path)
**Complexity**: Medium  
**Lines of Code**: ~800  
**Dependencies**: PostgreSQL, Redis, Kafka  

**Key Features:**
- User registration with validation
- Login with JWT generation
- Token storage in Redis (24h TTL)
- Token validation endpoint
- Kafka event publishing

**Challenges:**
- JWT secret management
- Redis connection handling
- Password hashing security

### Task Service (Core Business Logic)
**Complexity**: Medium  
**Lines of Code**: ~900  
**Dependencies**: PostgreSQL, Kafka, Auth Service  

**Key Features:**
- CRUD operations for tasks
- Task filtering and pagination
- Task statistics
- Auth service integration
- Kafka event publishing

**Challenges:**
- Auth service integration
- Pagination implementation
- Status transitions

### Notification Service (Simplest)
**Complexity**: Low  
**Lines of Code**: ~600  
**Dependencies**: PostgreSQL, Kafka, Auth Service  

**Key Features:**
- Kafka event consumption
- Notification storage
- Notification management API
- Mark as read functionality

**Challenges:**
- Kafka consumer error handling
- Event deserialization
- Message template generation

## Infrastructure Breakdown

### Complexity Matrix

| Component | Setup Complexity | Configuration Complexity | Total Effort |
|-----------|-----------------|-------------------------|--------------|
| PostgreSQL (3x) | Low | Medium | 3-4 hours |
| Redis | Low | Low | 30 minutes |
| Kafka | Medium | Medium | 2-3 hours |
| KrakenD | Medium | High | 3-4 hours |
| Graylog Stack | High | High | 4-5 hours |
| Prometheus | Low | Medium | 1-2 hours |
| Grafana | Low | Medium | 2-3 hours |
| Jaeger | Low | Low | 1 hour |

**Total Infrastructure Setup**: 17-24 hours

### Service Development Time

| Service | Development | Testing | Helm Chart | Total |
|---------|------------|---------|------------|-------|
| Auth Service | 8-10 hours | 3-4 hours | 2-3 hours | 13-17 hours |
| Task Service | 6-8 hours | 3-4 hours | 2-3 hours | 11-15 hours |
| Notification Service | 4-6 hours | 2-3 hours | 2-3 hours | 8-12 hours |

**Total Service Development**: 32-44 hours

### Integration & Testing

| Activity | Time Estimate |
|----------|--------------|
| End-to-end testing | 4-6 hours |
| Bug fixing | 4-8 hours |
| Documentation | 6-8 hours |
| Report preparation | 8-10 hours |
| Screenshots | 2-3 hours |

**Total Integration**: 24-35 hours

### Grand Total
**Estimated Project Time**: 73-103 hours (2-3 weeks full-time)

## Risk Assessment

### High Risk
🔴 **Graylog Setup Complexity**
- Mitigation: Use official Helm chart, follow documentation carefully
- Fallback: Use simpler logging (file-based with fluentd)

🔴 **Kafka Configuration**
- Mitigation: Use KRaft mode (no Zookeeper), single broker
- Fallback: Use RabbitMQ (simpler setup)

🔴 **KrakenD JWT Validation**
- Mitigation: Test thoroughly, use simple HS256 algorithm
- Fallback: Implement validation in each service

### Medium Risk
🟡 **Minikube Resource Constraints**
- Mitigation: Set appropriate resource limits, use 8GB RAM minimum
- Fallback: Use cloud Kubernetes (GKE, EKS)

🟡 **Service Communication Issues**
- Mitigation: Use Kubernetes DNS, test connectivity
- Fallback: Debug with curl from debug pod

🟡 **Persistent Volume Issues**
- Mitigation: Use standard storage class, test pod deletion
- Fallback: Use hostPath volumes

### Low Risk
🟢 **PostgreSQL Setup** - Well-documented, reliable
🟢 **Redis Setup** - Simple, single instance
🟢 **Prometheus Setup** - Standard Kubernetes integration
🟢 **Grafana Setup** - Easy datasource configuration

## Success Metrics

### Functional Requirements
- [ ] User can register and login
- [ ] User can create, read, update, delete tasks
- [ ] User receives notifications for task events
- [ ] All requests go through API Gateway
- [ ] Logs appear in Graylog with required fields
- [ ] Metrics visible in Grafana
- [ ] Traces visible in Jaeger
- [ ] Data persists after pod deletion

### Non-Functional Requirements
- [ ] Services scale with HPA (2-5 replicas)
- [ ] All health probes pass
- [ ] Response time < 500ms (p95)
- [ ] Zero downtime during rolling updates
- [ ] 80%+ test coverage
- [ ] All Helm charts deploy successfully

### Report Requirements
- [ ] Architecture diagram
- [ ] All configuration files shown
- [ ] Working system demonstration
- [ ] Kafka message flow shown
- [ ] Persistent volume demonstration
- [ ] All monitoring systems shown
- [ ] Screenshots with descriptions
- [ ] Questions answered

## Development Workflow

### Phase 1: Infrastructure Setup (Week 1)
1. Setup Minikube cluster
2. Deploy PostgreSQL instances with PVs
3. Deploy Redis
4. Deploy Kafka
5. Test basic connectivity

### Phase 2: Core Services (Week 1-2)
1. Implement Auth Service
   - User registration/login
   - JWT token management
   - Redis integration
   - Unit tests
2. Implement Task Service
   - CRUD operations
   - Auth integration
   - Unit tests
3. Implement Notification Service
   - Kafka consumer
   - Notification API
   - Unit tests

### Phase 3: Observability (Week 2)
1. Deploy Graylog stack
2. Configure GELF logging in services
3. Deploy Prometheus
4. Deploy Grafana with dashboards
5. Deploy Jaeger
6. Configure tracing in services

### Phase 4: API Gateway (Week 2-3)
1. Deploy KrakenD
2. Configure routes
3. Test JWT validation
4. Test end-to-end flows

### Phase 5: Helm Charts (Week 3)
1. Create Helm charts for all services
2. Configure HPA
3. Configure health probes
4. Configure resource limits
5. Test deployments

### Phase 6: Testing & Documentation (Week 3-4)
1. End-to-end testing
2. Load testing for HPA
3. Persistent volume testing
4. Screenshot collection
5. Report writing
6. Question preparation

## Testing Strategy

### Unit Tests
- JUnit 5 + MockK
- 80%+ coverage target
- Focus on business logic
- Mock external dependencies

### Integration Tests
- Testcontainers for PostgreSQL
- Testcontainers for Kafka
- Test actual database operations
- Test Kafka message flow

### End-to-End Tests
- Test complete user flows
- Test through API Gateway
- Verify Kafka events
- Check logs in Graylog
- Verify metrics in Prometheus
- Check traces in Jaeger

### Load Tests
- Generate load on services
- Verify HPA scaling
- Check resource usage
- Verify no errors under load

### Chaos Tests
- Delete pods, verify recovery
- Delete database pods, verify data persistence
- Stop Kafka, verify message retention
- Network issues, verify retries

## Deployment Checklist

### Pre-Deployment
- [ ] Minikube running with sufficient resources
- [ ] kubectl configured
- [ ] Helm installed
- [ ] All Docker images built
- [ ] Images loaded into Minikube

### Infrastructure Deployment
- [ ] Namespace created
- [ ] PostgreSQL instances deployed
- [ ] Redis deployed
- [ ] Kafka deployed
- [ ] Graylog stack deployed
- [ ] Prometheus deployed
- [ ] Grafana deployed
- [ ] Jaeger deployed
- [ ] All pods running

### Service Deployment
- [ ] Auth Service deployed
- [ ] Task Service deployed
- [ ] Notification Service deployed
- [ ] KrakenD deployed
- [ ] All services healthy
- [ ] HPA configured

### Verification
- [ ] Port forwarding setup
- [ ] API Gateway accessible
- [ ] User registration works
- [ ] User login works
- [ ] Task creation works
- [ ] Notifications created
- [ ] Logs in Graylog
- [ ] Metrics in Grafana
- [ ] Traces in Jaeger
- [ ] Persistent volumes working

## Troubleshooting Guide

### Common Issues

**Issue**: Pods stuck in Pending
- Check: `kubectl describe pod <pod-name>`
- Solution: Increase Minikube resources or reduce pod resource requests

**Issue**: Service can't connect to database
- Check: Service name, port, credentials
- Solution: Verify Secret values, check network policies

**Issue**: Kafka consumer not receiving messages
- Check: Topic exists, consumer group, offset
- Solution: Reset consumer group offset, check topic partitions

**Issue**: Graylog not receiving logs
- Check: GELF input configured, UDP port 12201 open
- Solution: Test with `nc -u graylog 12201`, check firewall

**Issue**: Prometheus not scraping metrics
- Check: Service discovery, target status
- Solution: Verify service labels, check /actuator/prometheus endpoint

**Issue**: HPA not scaling
- Check: Metrics server running, resource usage
- Solution: Generate load, verify metrics-server addon enabled

## Maintenance

### Regular Tasks
- Monitor pod resource usage
- Check log volume in Graylog
- Review Grafana dashboards
- Check for pod restarts
- Verify backup schedules (if implemented)

### Updates
- Update service images (rolling update)
- Update Helm chart values
- Update infrastructure components
- Apply security patches

### Monitoring
- Set up alerts for high error rates
- Monitor database connection pools
- Track Kafka consumer lag
- Watch for OOM kills

## Conclusion

This project demonstrates a complete microservices system with:
- Modern technology stack (Kotlin, Spring Boot, Kafka)
- Cloud-native deployment (Kubernetes, Helm)
- Comprehensive observability (Graylog, Prometheus, Grafana, Jaeger)
- Production-ready patterns (API Gateway, event-driven, database per service)
- Operational best practices (health probes, resource limits, HPA)

The system is designed to be:
- **Educational**: Clear examples of microservices patterns
- **Practical**: Real-world architecture decisions
- **Scalable**: Horizontal scaling with HPA
- **Observable**: Full visibility into system behavior
- **Maintainable**: Clean code, good documentation

Total estimated effort: 73-103 hours over 2-3 weeks.

