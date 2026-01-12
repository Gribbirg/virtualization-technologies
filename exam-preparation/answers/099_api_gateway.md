# Что такое API Gateway?

## Краткий ответ

API Gateway — это единая точка входа (entry point) для всех клиентских запросов в микросервисной архитектуре, которая маршрутизирует запросы к соответствующим backend сервисам. Основные функции: маршрутизация запросов, аутентификация и авторизация, агрегация данных от нескольких сервисов, rate limiting, кэширование, трансформация запросов/ответов, и обеспечение единого API интерфейса для клиентов.

## Развёрнутый ответ

### Определение и концепция

**API Gateway** — это архитектурный паттерн и серверный компонент, который действует как reverse proxy, принимая все API вызовы от клиентов, направляя их к соответствующим микросервисам, агрегируя результаты и возвращая ответ клиенту. Это реализация паттерна "Фасад" на уровне системы.

### Основные функции API Gateway

#### 1. Маршрутизация запросов (Request Routing)

**Описание:**
API Gateway определяет, к какому backend сервису направить входящий запрос на основе URL path, HTTP методов, headers или других параметров.

**Механизм работы:**
- URL-based routing: `/api/users/*` → User Service
- Header-based routing: версионирование через headers
- Query parameter routing: маршрутизация по параметрам
- Method-based routing: различные сервисы для GET/POST

**Пример:**
```
Client request: GET /api/users/123
API Gateway → User Service: GET /users/123

Client request: GET /api/orders/456
API Gateway → Order Service: GET /orders/456
```

**Преимущества:**
- Клиент не знает о внутренней структуре сервисов
- Простота изменения backend без влияния на клиентов
- Централизованная точка для routing rules

#### 2. Аутентификация и Авторизация (Authentication & Authorization)

**Описание:**
Централизованная проверка identity пользователя и прав доступа перед передачей запроса в backend сервисы.

**Функциональность:**
- **Authentication** — проверка identity (JWT, OAuth2, API keys)
- **Authorization** — проверка прав доступа (RBAC, ABAC)
- **Token validation** — проверка валидности и срока действия токенов
- **Token transformation** — конвертация external tokens в internal

**Механизмы:**
- JWT (JSON Web Tokens) validation
- OAuth 2.0 / OpenID Connect integration
- API Key management
- Basic Authentication
- Mutual TLS (mTLS)

**Преимущества:**
- Единое место для security logic
- Backend сервисы не дублируют auth logic
- Упрощение security audit
- Centralized token management

**Пример flow:**
```
1. Client sends request with JWT token
2. API Gateway validates token signature
3. API Gateway checks token expiration
4. API Gateway extracts user info from token
5. API Gateway adds user context to request headers
6. API Gateway routes to backend service
7. Backend service trusts Gateway's authentication
```

#### 3. Агрегация данных (Response Aggregation)

**Описание:**
Объединение данных от нескольких backend сервисов в единый ответ для клиента.

**Паттерны:**
- **API Composition** — вызов нескольких сервисов и объединение результатов
- **Backend for Frontend (BFF)** — специализированные gateway для разных типов клиентов
- **GraphQL Gateway** — unified query interface

**Пример:**
```
Client request: GET /api/user-dashboard/123

API Gateway:
1. Calls User Service: GET /users/123 → user data
2. Calls Order Service: GET /orders?userId=123 → orders
3. Calls Wallet Service: GET /wallet/123 → balance
4. Aggregates all responses into single JSON
5. Returns to client

Response:
{
  "user": {...},
  "orders": [...],
  "wallet": {...}
}
```

**Преимущества:**
- Уменьшение количества round trips от клиента
- Оптимизация для mobile/web клиентов
- Улучшение user experience
- Экономия bandwidth

**Недостатки:**
- Увеличенная сложность Gateway
- Tight coupling между Gateway и backend APIs
- Gateway становится bottleneck

#### 4. Rate Limiting и Throttling

**Описание:**
Ограничение количества запросов от клиентов для защиты backend сервисов от перегрузки.

**Стратегии:**
- **Per-user rate limiting** — лимит на пользователя
- **Per-API rate limiting** — лимит на endpoint
- **Global rate limiting** — общий лимит для системы
- **Burst handling** — обработка всплесков нагрузки

**Алгоритмы:**
- **Token Bucket** — токены пополняются с фиксированной скоростью
- **Leaky Bucket** — запросы обрабатываются с постоянной скоростью
- **Fixed Window** — фиксированное количество запросов за период
- **Sliding Window** — скользящее окно для более точного контроля

**Пример:**
- Бесплатный tier: 100 requests/hour
- Premium tier: 10,000 requests/hour
- Burst: до 200 requests/minute

**Преимущества:**
- Защита от DDoS атак
- Fair usage enforcement
- Monetization через tiers
- Backend services protection

#### 5. Кэширование (Caching)

**Описание:**
Сохранение ответов от backend сервисов для уменьшения нагрузки и улучшения latency.

**Типы кэширования:**
- **Response caching** — кэш полных ответов
- **Partial response caching** — кэш частей ответа
- **Cache-aside pattern** — проверка кэша перед backend вызовом

**Стратегии:**
- HTTP caching headers (Cache-Control, ETag)
- Time-based expiration (TTL)
- Cache invalidation strategies
- Cache warming для популярных endpoints

**Преимущества:**
- Уменьшение latency
- Снижение нагрузки на backend
- Улучшение scalability
- Экономия ресурсов

**Конфигурация:**
```
GET /api/products → cache for 5 minutes
GET /api/prices → cache for 1 minute
POST requests → never cache
```

#### 6. Трансформация запросов/ответов (Request/Response Transformation)

**Описание:**
Изменение формата, структуры или содержимого запросов и ответов между клиентами и backend.

**Типы трансформаций:**

**Request transformation:**
- Protocol translation (REST → gRPC)
- Header manipulation (добавление, удаление, изменение)
- Body transformation (JSON → XML, format changes)
- API versioning support
- Path rewriting

**Response transformation:**
- Filtering sensitive data
- Field renaming для backward compatibility
- Format conversion
- Error response standardization
- Response wrapping

**Пример:**
```
Client request (REST):
GET /api/v1/users/123

API Gateway transforms to gRPC:
UserService.GetUser(userId: 123)

Backend response (protobuf):
user { id: 123, name: "John" }

API Gateway transforms to JSON:
{ "id": 123, "name": "John" }
```

**Преимущества:**
- Backend и frontend независимы в форматах
- Легкость миграции протоколов
- Backward compatibility
- API evolution без breaking changes

#### 7. Load Balancing

**Описание:**
Распределение входящих запросов между несколькими экземплярами backend сервисов.

**Алгоритмы:**
- **Round Robin** — последовательное распределение
- **Least Connections** — к инстансу с меньшим числом соединений
- **Weighted** — с учетом capacity инстансов
- **IP Hash** — на основе client IP для stickiness
- **Least Response Time** — к самому быстрому инстансу

**Health Checks:**
- Active health checks (periodic pinging)
- Passive health checks (monitoring actual traffic)
- Circuit breaker integration
- Auto-removal unhealthy instances

**Преимущества:**
- High availability
- Fault tolerance
- Scalability
- Optimal resource utilization

#### 8. Service Discovery Integration

**Описание:**
Динамическое определение местоположения backend сервисов.

**Механизм:**
- Интеграция с service registry (Consul, Eureka, etcd)
- Dynamic service lookup
- Automatic updates при изменении топологии
- DNS-based discovery

**Пример:**
```
API Gateway:
1. Receives request for User Service
2. Queries Service Registry: "Where is User Service?"
3. Registry returns: ["10.0.1.5:8080", "10.0.1.6:8080"]
4. Gateway load balances between instances
5. Sends request to selected instance
```

#### 9. Мониторинг и Логирование (Monitoring & Logging)

**Описание:**
Централизованный сбор метрик и логов всех API вызовов.

**Метрики:**
- Request rate (requests per second)
- Error rate и status codes distribution
- Latency percentiles (p50, p95, p99)
- Throughput и bandwidth
- Backend service health

**Логирование:**
- Access logs всех requests
- Error logs с stack traces
- Audit logs для compliance
- Correlation IDs для distributed tracing

**Интеграция:**
- Prometheus для metrics
- ELK stack для logs
- Grafana для dashboards
- Jaeger/Zipkin для tracing

**Преимущества:**
- Единая точка для observability
- Упрощение troubleshooting
- Business intelligence данные
- SLA monitoring

#### 10. Security функции

**Описание:**
Дополнительные security меры для защиты backend.

**Функции:**
- **DDoS protection** — защита от атак
- **IP whitelisting/blacklisting** — контроль доступа по IP
- **SSL/TLS termination** — offload encryption от backend
- **Request validation** — проверка schema, sanitization
- **CORS handling** — Cross-Origin Resource Sharing
- **Bot detection** — защита от ботов

### Популярные реализации API Gateway

#### Cloud-native решения

**Amazon API Gateway**
- Fully managed AWS service
- Integration с Lambda, ECS, EC2
- Built-in caching и throttling
- CloudWatch integration
- Custom domain names
- API Keys management

**Azure API Management**
- Enterprise-grade gateway
- Developer portal out-of-the-box
- Policy-based configuration
- Multiple environments support
- Azure AD integration

**Google Cloud API Gateway**
- Managed gateway для GCP
- OpenAPI specification support
- Cloud Endpoints integration
- Cloud Armor для DDoS protection

#### Open Source решения

**Kong**
- High-performance gateway
- Plugin architecture (50+ plugins)
- Multiple protocols support (HTTP, gRPC, WebSocket)
- Clustering для high availability
- Admin API для управления
- Community и Enterprise editions

**Nginx / Nginx Plus**
- Proven reverse proxy
- High performance и low latency
- Extensive configuration options
- Nginx Plus — commercial version с additional features
- Wide adoption и community

**Traefik**
- Modern cloud-native gateway
- Automatic service discovery
- Kubernetes-native
- Let's Encrypt integration
- Dynamic configuration
- Dashboard included

**KrakenD**
- Ultra-fast API Gateway
- Declarative configuration
- No database required
- Built for microservices
- Circuit breaker included

**Envoy Proxy**
- L7 proxy от Lyft
- Service mesh foundation
- Advanced load balancing
- Observability built-in
- Used in Istio

#### Framework-based

**Spring Cloud Gateway**
- Java-based gateway
- Reactive programming model (WebFlux)
- Spring ecosystem integration
- Predicates и Filters для routing
- Circuit breaker integration

**Express Gateway**
- Node.js based
- Built on Express.js
- Plugin system
- Lightweight
- Easy to extend

### Паттерны использования

#### Backend for Frontend (BFF)

**Концепция:**
Отдельные API Gateway для различных типов клиентов.

**Структура:**
```
Mobile App → Mobile BFF → Microservices
Web App → Web BFF → Microservices
IoT Devices → IoT BFF → Microservices
```

**Преимущества:**
- Оптимизация для каждого типа клиента
- Независимая эволюция BFF
- Team ownership по типу клиента
- Уменьшение сложности одного gateway

**Недостатки:**
- Дублирование логики между BFF
- Больше компонентов для поддержки

#### GraphQL Gateway

**Концепция:**
API Gateway предоставляет GraphQL интерфейс поверх REST/gRPC backend.

**Преимущества:**
- Единый query language
- Клиент запрашивает только нужные данные
- Strong typing
- Single request для complex data

#### Service Mesh vs API Gateway

**Service Mesh (Istio, Linkerd):**
- Service-to-service communication
- East-West traffic
- Inside cluster
- Advanced traffic management

**API Gateway:**
- External-to-internal communication
- North-South traffic
- Cluster entry point
- Client-facing API

**Взаимодополнение:**
Часто используются вместе — Gateway для external traffic, Service Mesh для internal.

### Преимущества API Gateway

1. **Упрощение клиентов** — единая точка доступа
2. **Безопасность** — централизованная аутентификация
3. **Мониторинг** — единое место для observability
4. **Масштабируемость** — offload логики от backend
5. **Гибкость** — легкость изменения backend без влияния на клиентов
6. **Performance** — кэширование, compression

### Недостатки и риски

1. **Single Point of Failure** — критическая точка отказа
2. **Performance bottleneck** — может стать узким местом
3. **Increased complexity** — дополнительный компонент
4. **Latency overhead** — дополнительный hop
5. **Development bottleneck** — изменения в Gateway требуют coordination
6. **Tight coupling риск** — особенно при агрегации

### Best Practices

1. **High Availability** — redundancy для Gateway
2. **Stateless design** — для горизонтального масштабирования
3. **Health checks** — мониторинг backend сервисов
4. **Timeout configuration** — для всех backend вызовов
5. **Circuit breaker** — защита от cascading failures
6. **Rate limiting** — защита backend
7. **Observability** — comprehensive logging и metrics
8. **Security** — defense in depth
9. **API versioning** — backward compatibility
10. **Documentation** — для consumers API

## Источники

Информация основана на:
- Chris Richardson "Microservices Patterns" — API Gateway pattern
- Sam Newman "Building Microservices" — главы о Gateway
- Официальная документация Kong, NGINX, AWS API Gateway, Azure APIM
- "Designing Distributed Systems" by Brendan Burns
- Cloud Native Computing Foundation (CNCF) best practices
- Phil Calçado статьи о BFF pattern
- Netflix tech blog о Zuul (их API Gateway)
