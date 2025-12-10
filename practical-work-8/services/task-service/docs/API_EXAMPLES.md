# Task Service - API Examples

## Authentication

All endpoints require JWT token obtained from Auth Service.

### Get Token

```bash
# Register user
curl -X POST http://localhost:8081/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@example.com",
    "password": "SecurePass123!"
  }'

# Login
TOKEN=$(curl -s -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "password": "SecurePass123!"
  }' | jq -r '.token')

echo "Token: $TOKEN"
```

## Task Operations

### 1. Create Task

```bash
curl -X POST http://localhost:8082/api/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Implement user authentication",
    "description": "Add JWT-based authentication to the API",
    "status": "PENDING"
  }'
```

**Response:**
```json
{
  "id": 1,
  "userId": 1,
  "title": "Implement user authentication",
  "description": "Add JWT-based authentication to the API",
  "status": "PENDING",
  "createdAt": "2025-12-03T10:00:00Z",
  "updatedAt": "2025-12-03T10:00:00Z"
}
```

### 2. Get All Tasks

```bash
# Get all tasks
curl -X GET http://localhost:8082/api/tasks \
  -H "Authorization: Bearer $TOKEN"

# With pagination
curl -X GET "http://localhost:8082/api/tasks?page=0&size=10" \
  -H "Authorization: Bearer $TOKEN"

# Filter by status
curl -X GET "http://localhost:8082/api/tasks?status=PENDING" \
  -H "Authorization: Bearer $TOKEN"

# Filter and paginate
curl -X GET "http://localhost:8082/api/tasks?status=IN_PROGRESS&page=0&size=20" \
  -H "Authorization: Bearer $TOKEN"
```

**Response:**
```json
{
  "content": [
    {
      "id": 1,
      "userId": 1,
      "title": "Implement user authentication",
      "description": "Add JWT-based authentication to the API",
      "status": "PENDING",
      "createdAt": "2025-12-03T10:00:00Z",
      "updatedAt": "2025-12-03T10:00:00Z"
    }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 1,
  "totalPages": 1
}
```

### 3. Get Task by ID

```bash
TASK_ID=1

curl -X GET http://localhost:8082/api/tasks/$TASK_ID \
  -H "Authorization: Bearer $TOKEN"
```

**Response:**
```json
{
  "id": 1,
  "userId": 1,
  "title": "Implement user authentication",
  "description": "Add JWT-based authentication to the API",
  "status": "PENDING",
  "createdAt": "2025-12-03T10:00:00Z",
  "updatedAt": "2025-12-03T10:00:00Z"
}
```

### 4. Update Task

```bash
TASK_ID=1

curl -X PUT http://localhost:8082/api/tasks/$TASK_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Implement user authentication (Updated)",
    "description": "Add JWT-based authentication with Redis storage",
    "status": "IN_PROGRESS"
  }'
```

**Response:**
```json
{
  "id": 1,
  "userId": 1,
  "title": "Implement user authentication (Updated)",
  "description": "Add JWT-based authentication with Redis storage",
  "status": "IN_PROGRESS",
  "createdAt": "2025-12-03T10:00:00Z",
  "updatedAt": "2025-12-03T11:00:00Z"
}
```

### 5. Complete Task

```bash
TASK_ID=1

curl -X PUT http://localhost:8082/api/tasks/$TASK_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Implement user authentication",
    "description": "Add JWT-based authentication with Redis storage",
    "status": "COMPLETED"
  }'
```

### 6. Cancel Task

```bash
TASK_ID=1

curl -X PUT http://localhost:8082/api/tasks/$TASK_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Implement user authentication",
    "description": "Task cancelled due to priority change",
    "status": "CANCELLED"
  }'
```

### 7. Delete Task

```bash
TASK_ID=1

curl -X DELETE http://localhost:8082/api/tasks/$TASK_ID \
  -H "Authorization: Bearer $TOKEN"
```

**Response:** 204 No Content

### 8. Get Task Statistics

```bash
curl -X GET http://localhost:8082/api/tasks/stats \
  -H "Authorization: Bearer $TOKEN"
```

**Response:**
```json
{
  "userId": 1,
  "totalTasks": 10,
  "pendingTasks": 3,
  "inProgressTasks": 2,
  "completedTasks": 4,
  "cancelledTasks": 1
}
```

## Error Responses

### 401 Unauthorized

Missing or invalid token:
```bash
curl -X GET http://localhost:8082/api/tasks
```

**Response:**
```json
{
  "error": "Unauthorized - invalid or missing token"
}
```

### 403 Forbidden

Trying to access another user's task:
```json
{
  "error": "Access denied - task belongs to another user"
}
```

### 404 Not Found

Task doesn't exist:
```json
{
  "error": "Task not found",
  "taskId": 999
}
```

### 400 Bad Request

Validation error:
```json
{
  "error": "Validation failed",
  "details": {
    "title": "Title is required",
    "status": "Invalid status value"
  }
}
```

## Health & Metrics

### Health Check

```bash
curl http://localhost:8082/actuator/health
```

**Response:**
```json
{
  "status": "UP"
}
```

### Liveness Probe

```bash
curl http://localhost:8082/actuator/health/liveness
```

### Readiness Probe

```bash
curl http://localhost:8082/actuator/health/readiness
```

### Prometheus Metrics

```bash
curl http://localhost:8082/actuator/prometheus
```

**Sample metrics:**
```
# HELP tasks_created_total Total number of tasks created
# TYPE tasks_created_total counter
tasks_created_total 15.0

# HELP tasks_updated_total Total number of tasks updated
# TYPE tasks_updated_total counter
tasks_updated_total 8.0

# HELP tasks_deleted_total Total number of tasks deleted
# TYPE tasks_deleted_total counter
tasks_deleted_total 3.0
```

## Batch Operations

### Create Multiple Tasks

```bash
for i in {1..5}; do
  curl -X POST http://localhost:8082/api/tasks \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{
      \"title\": \"Task $i\",
      \"description\": \"Description for task $i\",
      \"status\": \"PENDING\"
    }"
  sleep 0.5
done
```

### Update Multiple Tasks

```bash
for id in 1 2 3 4 5; do
  curl -X PUT http://localhost:8082/api/tasks/$id \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
      "title": "Updated Task",
      "description": "Batch updated",
      "status": "IN_PROGRESS"
    }'
  sleep 0.5
done
```

## Testing Workflow

### Complete User Journey

```bash
#!/bin/bash

# 1. Register and login
TOKEN=$(curl -s -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"john_doe","password":"SecurePass123!"}' \
  | jq -r '.token')

# 2. Create task
TASK_ID=$(curl -s -X POST http://localhost:8082/api/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Complete project",
    "description": "Finish all tasks",
    "status": "PENDING"
  }' | jq -r '.id')

echo "Created task: $TASK_ID"

# 3. Start working on task
curl -s -X PUT http://localhost:8082/api/tasks/$TASK_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Complete project",
    "description": "Finish all tasks - In progress",
    "status": "IN_PROGRESS"
  }' | jq '.'

# 4. Complete task
curl -s -X PUT http://localhost:8082/api/tasks/$TASK_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Complete project",
    "description": "Finish all tasks - Completed!",
    "status": "COMPLETED"
  }' | jq '.'

# 5. View statistics
curl -s -X GET http://localhost:8082/api/tasks/stats \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

## Swagger UI

Access interactive API documentation:

```
http://localhost:8082/swagger-ui.html
```

Features:
- Try out all endpoints
- View request/response schemas
- See validation rules
- Test authentication

## Postman Collection

Import this collection to Postman:

```json
{
  "info": {
    "name": "Task Service API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Create Task",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{token}}"
          }
        ],
        "url": "{{baseUrl}}/api/tasks",
        "body": {
          "mode": "raw",
          "raw": "{\n  \"title\": \"Test Task\",\n  \"description\": \"Test\",\n  \"status\": \"PENDING\"\n}"
        }
      }
    }
  ],
  "variable": [
    {
      "key": "baseUrl",
      "value": "http://localhost:8082"
    },
    {
      "key": "token",
      "value": "your-jwt-token"
    }
  ]
}
```

