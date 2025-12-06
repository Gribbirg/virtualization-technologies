# Task Service - Kafka Events

## Overview

Task Service publishes events to Kafka topic `task-events` for all task operations. These events are consumed by Notification Service to create user notifications.

## Topic Configuration

**Topic Name:** `task-events`  
**Partitions:** 3  
**Replication Factor:** 1 (for development)  

## Event Types

### 1. TASK_CREATED

Published when a new task is created.

**Event Structure:**
```json
{
  "eventType": "TASK_CREATED",
  "taskId": 1,
  "userId": 1,
  "title": "Implement user authentication",
  "status": "PENDING",
  "timestamp": "2025-12-03T10:00:00Z"
}
```

**Fields:**
- `eventType` (string): Always "TASK_CREATED"
- `taskId` (long): ID of the created task
- `userId` (long): ID of the user who created the task
- `title` (string): Task title
- `status` (string): Initial task status (usually PENDING)
- `timestamp` (ISO-8601): Event creation timestamp

**Notification Message:**
```
"Task created: Implement user authentication"
```

### 2. TASK_UPDATED

Published when a task is updated (title, description, or status change).

**Event Structure:**
```json
{
  "eventType": "TASK_UPDATED",
  "taskId": 1,
  "userId": 1,
  "title": "Implement user authentication",
  "oldStatus": "PENDING",
  "newStatus": "IN_PROGRESS",
  "timestamp": "2025-12-03T11:00:00Z"
}
```

**Fields:**
- `eventType` (string): Always "TASK_UPDATED"
- `taskId` (long): ID of the updated task
- `userId` (long): ID of the user who owns the task
- `title` (string): Current task title
- `oldStatus` (string): Previous task status
- `newStatus` (string): New task status
- `timestamp` (ISO-8601): Event creation timestamp

**Notification Message:**
```
"Task updated: Implement user authentication (PENDING → IN_PROGRESS)"
```

### 3. TASK_COMPLETED

Published when a task status changes to COMPLETED.

**Event Structure:**
```json
{
  "eventType": "TASK_COMPLETED",
  "taskId": 1,
  "userId": 1,
  "title": "Implement user authentication",
  "timestamp": "2025-12-03T12:00:00Z"
}
```

**Fields:**
- `eventType` (string): Always "TASK_COMPLETED"
- `taskId` (long): ID of the completed task
- `userId` (long): ID of the user who owns the task
- `title` (string): Task title
- `timestamp` (ISO-8601): Event creation timestamp

**Notification Message:**
```
"Task completed: Implement user authentication"
```

### 4. TASK_DELETED

Published when a task is deleted.

**Event Structure:**
```json
{
  "eventType": "TASK_DELETED",
  "taskId": 1,
  "userId": 1,
  "timestamp": "2025-12-03T13:00:00Z"
}
```

**Fields:**
- `eventType` (string): Always "TASK_DELETED"
- `taskId` (long): ID of the deleted task
- `userId` (long): ID of the user who owned the task
- `timestamp` (ISO-8601): Event creation timestamp

**Notification Message:**
```
"Task deleted: Task #1"
```

## Event Flow

### Create Task Flow

```
1. User → POST /api/tasks
2. TaskService → Save to PostgreSQL
3. TaskService → Publish TASK_CREATED event to Kafka
4. Kafka → Store event in task-events topic
5. NotificationService → Consume event
6. NotificationService → Create notification in PostgreSQL
7. TaskService → Return response to user
```

### Update Task Flow

```
1. User → PUT /api/tasks/{id}
2. TaskService → Update in PostgreSQL
3. TaskService → Publish TASK_UPDATED event to Kafka
4. If status changed to COMPLETED:
   TaskService → Publish TASK_COMPLETED event to Kafka
5. Kafka → Store events in task-events topic
6. NotificationService → Consume events
7. NotificationService → Create notifications in PostgreSQL
8. TaskService → Return response to user
```

### Delete Task Flow

```
1. User → DELETE /api/tasks/{id}
2. TaskService → Delete from PostgreSQL
3. TaskService → Publish TASK_DELETED event to Kafka
4. Kafka → Store event in task-events topic
5. NotificationService → Consume event
6. NotificationService → Create notification in PostgreSQL
7. TaskService → Return 204 No Content
```

## Testing Kafka Events

### View Kafka Topics

```bash
kubectl exec -n task-management kafka-0 -- \
  kafka-topics --bootstrap-server localhost:9092 --list
```

### Create Topic Manually (if needed)

```bash
kubectl exec -n task-management kafka-0 -- \
  kafka-topics --bootstrap-server localhost:9092 \
  --create --topic task-events --partitions 3 --replication-factor 1
```

### Consume Events

```bash
kubectl exec -n task-management kafka-0 -- \
  kafka-console-consumer --bootstrap-server localhost:9092 \
  --topic task-events --from-beginning
```

### Produce Test Event

```bash
kubectl exec -n task-management kafka-0 -- \
  kafka-console-producer --bootstrap-server localhost:9092 \
  --topic task-events
```

Then paste:
```json
{"eventType":"TASK_CREATED","taskId":999,"userId":1,"title":"Test Task","status":"PENDING","timestamp":"2025-12-03T10:00:00Z"}
```

### Check Consumer Groups

```bash
kubectl exec -n task-management kafka-0 -- \
  kafka-consumer-groups --bootstrap-server localhost:9092 --list
```

### View Consumer Lag

```bash
kubectl exec -n task-management kafka-0 -- \
  kafka-consumer-groups --bootstrap-server localhost:9092 \
  --group notification-service-group --describe
```

## Event Publishing Code

### KafkaProducerService

```kotlin
@Service
class KafkaProducerService(
    private val kafkaTemplate: KafkaTemplate<String, Any>
) {
    private val topic = "task-events"

    fun publishTaskCreated(taskId: Long, userId: Long, title: String, status: String) {
        val event = mapOf(
            "eventType" to "TASK_CREATED",
            "taskId" to taskId,
            "userId" to userId,
            "title" to title,
            "status" to status,
            "timestamp" to Instant.now().toString()
        )
        kafkaTemplate.send(topic, event)
    }
}
```

### Usage in TaskService

```kotlin
@Transactional
fun createTask(request: CreateTaskRequest, userId: Long): TaskResponse {
    val task = Task(...)
    val savedTask = taskRepository.save(task)
    
    // Publish event
    kafkaProducerService.publishTaskCreated(
        taskId = savedTask.id!!,
        userId = userId,
        title = savedTask.title,
        status = savedTask.status.name
    )
    
    return TaskResponse.from(savedTask)
}
```

## Error Handling

### Kafka Unavailable

If Kafka is unavailable, events are logged but not published. The task operation still succeeds.

```kotlin
private fun publishEvent(event: Map<String, Any>) {
    try {
        kafkaTemplate.send(topic, event)
        logger.info("Published event to Kafka: ${event["eventType"]}")
    } catch (e: Exception) {
        logger.error("Failed to publish event to Kafka: ${e.message}", e)
        // Task operation continues - event publishing is non-blocking
    }
}
```

### Retry Configuration

Configure in `application.yml`:

```yaml
spring:
  kafka:
    producer:
      retries: 3
      acks: 1
      properties:
        retry.backoff.ms: 1000
```

## Monitoring

### Prometheus Metrics

```promql
# Kafka producer metrics
kafka_producer_record_send_total
kafka_producer_record_error_total
kafka_producer_request_latency_avg
```

### Check in Grafana

```promql
# Events published per minute
rate(kafka_producer_record_send_total{topic="task-events"}[1m])

# Failed events
rate(kafka_producer_record_error_total{topic="task-events"}[1m])
```

## Event Schema Validation

### JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "TaskEvent",
  "type": "object",
  "required": ["eventType", "taskId", "userId", "timestamp"],
  "properties": {
    "eventType": {
      "type": "string",
      "enum": ["TASK_CREATED", "TASK_UPDATED", "TASK_COMPLETED", "TASK_DELETED"]
    },
    "taskId": {
      "type": "integer",
      "minimum": 1
    },
    "userId": {
      "type": "integer",
      "minimum": 1
    },
    "title": {
      "type": "string",
      "maxLength": 200
    },
    "status": {
      "type": "string",
      "enum": ["PENDING", "IN_PROGRESS", "COMPLETED", "CANCELLED"]
    },
    "oldStatus": {
      "type": "string"
    },
    "newStatus": {
      "type": "string"
    },
    "timestamp": {
      "type": "string",
      "format": "date-time"
    }
  }
}
```

## Best Practices

### 1. Event Ordering

Events for the same task should be processed in order. Use `taskId` as partition key:

```kotlin
kafkaTemplate.send(topic, taskId.toString(), event)
```

### 2. Idempotency

Consumers should handle duplicate events gracefully:
- Check if notification already exists
- Use unique constraint on (userId, eventType, taskId)

### 3. Event Versioning

Include version field for future compatibility:

```json
{
  "eventVersion": "1.0",
  "eventType": "TASK_CREATED",
  ...
}
```

### 4. Dead Letter Queue

Configure DLQ for failed events:

```yaml
spring:
  kafka:
    producer:
      properties:
        enable.idempotence: true
```

## Troubleshooting

### Events not appearing in Kafka

1. Check Kafka is running:
```bash
kubectl get pods -n task-management -l app=kafka
```

2. Check producer logs:
```bash
kubectl logs -n task-management -l app=task-service | grep "Kafka"
```

3. Test connectivity:
```bash
kubectl exec -n task-management task-service-xxx -- \
  nc -zv kafka 9092
```

### Consumer not receiving events

1. Check consumer group:
```bash
kubectl logs -n task-management -l app=notification-service
```

2. Check consumer lag:
```bash
kubectl exec -n task-management kafka-0 -- \
  kafka-consumer-groups --bootstrap-server localhost:9092 \
  --group notification-service-group --describe
```

3. Reset consumer offset:
```bash
kubectl exec -n task-management kafka-0 -- \
  kafka-consumer-groups --bootstrap-server localhost:9092 \
  --group notification-service-group --reset-offsets \
  --to-earliest --topic task-events --execute
```

