# 87. Назовите и опишите уровни событий, происходящих в аудитных логах

## Краткий ответ

Уровни событий в аудитных логах классифицируют события по степени важности и критичности. Стандартные уровни включают: CRITICAL/FATAL (критические сбои), ERROR (ошибки требующие внимания), WARNING (предупреждения о потенциальных проблемах), INFO (информационные события), DEBUG (детальная отладочная информация) и TRACE (максимально детальная трассировка). Эта классификация позволяет эффективно фильтровать, анализировать и реагировать на события в соответствии с их важностью.

## Развёрнутый ответ

Уровни событий (log levels) в аудитных логах представляют собой стандартизированную систему классификации событий по степени их важности, критичности и необходимости реагирования. Правильная классификация событий критически важна для эффективного мониторинга, анализа безопасности и troubleshooting.

### Стандартные уровни событий:

### 1. CRITICAL / FATAL (Критический уровень)

**Описание**: События, представляющие критические сбои системы, которые требуют немедленного вмешательства и могут привести к полной неработоспособности сервиса.

**Характеристики**:
- Максимальная приоритетность
- Требует немедленной реакции и эскалации
- Обычно приводит к недоступности сервиса или потере данных
- Автоматически создаёт critical alerts и инциденты

**Примеры событий**:
- Полный отказ базы данных или критического сервиса
- Исчерпание дискового пространства на production системах
- Критические security incidents (успешная атака, data breach)
- Отказ всех узлов в кластере
- Corruption критически важных данных
- Catastrophic hardware failures
- Total loss of network connectivity

**Действия**:
- Немедленное оповещение on-call team
- Activation disaster recovery procedures
- Escalation к senior management при необходимости
- War room созыв для критических инцидентов

### 2. ERROR (Ошибка)

**Описание**: События, указывающие на ошибки в работе системы, которые требуют внимания, но не приводят к полному отказу сервиса.

**Характеристики**:
- Высокая приоритетность
- Требует расследования и исправления
- Может влиять на функциональность, но система продолжает работать
- Генерирует alerts для ответственных команд

**Примеры событий**:
- Ошибки подключения к базе данных (connection timeouts)
- Failed API calls и HTTP 5xx errors
- Exceptions в application code
- Failed authentication attempts превышающие threshold
- Failed backup operations
- Resource allocation failures (OOM errors)
- Configuration errors preventing feature functionality
- Failed message processing в queues
- Certificate expiration warnings (близкие к expiry)
- Permission denied errors для критичных операций

**Действия**:
- Investigation в течение определённого SLA
- Error tracking и trending analysis
- Bug reporting и prioritization для fix
- Potential rollback если связано с recent deployment

### 3. WARNING / WARN (Предупреждение)

**Описание**: События, указывающие на потенциальные проблемы или нештатные ситуации, которые не являются ошибками, но требуют внимания для предотвращения будущих проблем.

**Характеристики**:
- Средняя приоритетность
- Указывает на деградацию или risk factors
- Система работает, но не оптимально
- Может не требовать немедленных действий, но должно отслеживаться

**Примеры событий**:
- Высокое использование ресурсов (CPU > 80%, memory > 85%)
- Increased latency или response times
- Deprecated API usage warnings
- Retry attempts для failed operations
- Approaching quota limits (80-90% utilization)
- Configuration drift detected
- Non-critical service degradation
- Connection pool exhaustion warnings
- Cache miss rate increase
- Slow database queries
- Security policy violations (non-critical)
- SSL certificate approaching expiration (30-60 days)

**Действия**:
- Monitoring и trending
- Capacity planning adjustments
- Preventive maintenance scheduling
- Code optimization consideration
- Documentation для known issues

### 4. INFO / INFORMATION (Информационный)

**Описание**: Информационные события, отражающие нормальную работу системы и важные вехи в бизнес-процессах.

**Характеристики**:
- Нормальная приоритетность
- Документирует нормальное поведение системы
- Не требует действий, но важно для audit trail
- Используется для трассировки бизнес-операций

**Примеры событий**:
- User login/logout events
- Successful API calls для важных операций
- Configuration changes applied
- Service startup/shutdown events
- Deployment completions
- Scheduled job executions
- Data synchronization completions
- Resource provisioning events
- State transitions в workflows
- Payment processing success
- Order creation/completion
- User registration events
- Email/notification sent successfully
- Cache invalidation events
- Health check successes (периодически)

**Использование**:
- Audit trails для compliance
- Business analytics и reporting
- User behavior tracking
- Performance baseline establishment
- Forensic analysis при инцидентах

### 5. DEBUG (Отладочный)

**Описание**: Детальная отладочная информация, полезная для разработчиков при диагностике проблем и понимании внутренней работы системы.

**Характеристики**:
- Низкая приоритетность (в production обычно отключен)
- Высокий объём данных
- Детали внутренних операций и flow control
- Используется преимущественно в development/staging

**Примеры событий**:
- Function entry/exit points
- Variable values и state changes
- SQL queries и их parameters
- API request/response bodies (sanitized)
- Cache operations (hits, misses, invalidations)
- Internal calculations и intermediate results
- State machine transitions с details
- Algorithm execution steps
- Configuration loading details
- Dependency injection resolutions
- Middleware processing details
- Validation rule execution

**Использование**:
- Development и local debugging
- Troubleshooting complex issues в non-production
- Performance profiling
- Understanding code flow
- Integration testing

### 6. TRACE (Трассировочный)

**Описание**: Максимально детальная информация о выполнении, включая мельчайшие детали операций. Самый verbose уровень логирования.

**Характеристики**:
- Минимальная приоритетность
- Чрезвычайно высокий объём данных
- Очень детальная информация о каждом шаге
- Практически никогда не используется в production

**Примеры событий**:
- Каждый loop iteration
- Каждый method call с полными параметрами
- Byte-level data processing
- Network packet details
- Memory allocation/deallocation
- Thread/coroutine scheduling details
- Detailed timer measurements
- Every condition evaluation
- Низкоуровневые системные вызовы

**Использование**:
- Глубокая отладка специфичных проблем
- Performance tuning на micro-level
- Security research и reverse engineering
- Protocol implementation debugging

### Специализированные уровни в различных системах:

**Syslog Severity Levels (RFC 5424)**:
- 0 - Emergency: система неработоспособна
- 1 - Alert: необходимы немедленные действия
- 2 - Critical: критические условия
- 3 - Error: ошибки
- 4 - Warning: предупреждения
- 5 - Notice: нормальные, но значительные события
- 6 - Informational: информационные сообщения
- 7 - Debug: отладочные сообщения

**Windows Event Log Levels**:
- Critical
- Error
- Warning
- Information
- Verbose

**Cloud Provider Specific**:

**AWS CloudTrail/CloudWatch**:
- Events классифицируются по типам (Management, Data, Insights events)
- Severity определяется через custom metrics и alarms

**Azure Monitor**:
- Critical, Error, Warning, Informational, Verbose
- Security-specific: High, Medium, Low, Informational

**Google Cloud Logging**:
- DEFAULT, DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL, ALERT, EMERGENCY

### Лучшие практики использования уровней:

1. **Production Configuration**:
   - Обычно INFO и выше для application logs
   - WARNING и выше для less critical services
   - ERROR и выше для high-volume services
   - DEBUG только для specific troubleshooting

2. **Log Volume Management**:
   - Балансировка между детализацией и объёмом
   - Sampling для DEBUG/TRACE в production
   - Dynamic log level adjustment при необходимости
   - Retention policies based на level

3. **Alerting Strategy**:
   - CRITICAL → Immediate paging (24/7)
   - ERROR → Alert during business hours или after threshold
   - WARNING → Aggregated daily reports
   - INFO и ниже → No alerting, только для analysis

4. **Security Logging**:
   - Authentication failures: WARNING (single) → ERROR (repeated)
   - Authorization violations: ERROR
   - Security policy changes: INFO
   - Detected attacks: CRITICAL
   - Suspicious activity: WARNING

5. **Performance Impact**:
   - TRACE/DEBUG: Significant overhead
   - INFO: Moderate overhead
   - ERROR/CRITICAL: Minimal overhead
   - Asynchronous logging для minimizing impact

### Контекстная информация в логах (помимо уровня):

- **Timestamp**: точное время события (UTC)
- **Source**: service, component, module
- **User context**: user ID, session ID
- **Request context**: request ID, correlation ID для distributed tracing
- **Environment**: production, staging, development
- **Location**: datacenter, region, availability zone
- **Additional metadata**: tags, labels, custom fields

## Источники

- RFC 5424: The Syslog Protocol
- OWASP Logging Cheat Sheet
- NIST SP 800-92: Guide to Computer Security Log Management
- Cloud Native Computing Foundation (CNCF) Logging Best Practices
- AWS CloudWatch Logs Documentation
- Azure Monitor Logs Documentation
- Google Cloud Logging Documentation
- Splunk Logging Best Practices
- ELK Stack Documentation
- The Twelve-Factor App: Logs section
