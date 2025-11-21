# API Examples

This document contains examples of API requests for testing the Spring Boot application.

## Users API (CRUD)

### GET - Get all users
```bash
curl http://localhost:8090/api/users
```

### GET - Get user by ID
```bash
curl http://localhost:8090/api/users/1
```

### POST - Create new user
```bash
curl -X POST http://localhost:8090/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"petrov","email":"petrov@mirea.ru","firstName":"Петр","lastName":"Петров"}'
```

### PUT - Update user
```bash
curl -X PUT http://localhost:8090/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{"username":"ivanov","email":"ivanov@mirea.ru","firstName":"Иван","lastName":"Иванов Обновлённый"}'
```

### DELETE - Delete user
```bash
curl -X DELETE http://localhost:8090/api/users/1
```

## Products API (CRUD)

### GET - Get all products
```bash
curl http://localhost:8090/api/products
```

### GET - Get product by ID
```bash
curl http://localhost:8090/api/products/1
```

### POST - Create new product
```bash
curl -X POST http://localhost:8090/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Клавиатура Logitech","description":"Механическая клавиатура","price":5500.00,"stock":15}'
```

### PUT - Update product
```bash
curl -X PUT http://localhost:8090/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"Ноутбук ASUS ROG","description":"Игровой ноутбук обновлённый","price":95000.00,"stock":3}'
```

### DELETE - Delete product
```bash
curl -X DELETE http://localhost:8090/api/products/1
```

## Orders API (CRUD)

### GET - Get all orders
```bash
curl http://localhost:8090/api/orders
```

### GET - Get order by ID
```bash
curl http://localhost:8090/api/orders/1
```

### POST - Create new order
```bash
curl -X POST http://localhost:8090/api/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"productIds":[1,2],"totalAmount":100000.00}'
```

### PUT - Update order
```bash
curl -X PUT http://localhost:8090/api/orders/1 \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"productIds":[1],"totalAmount":85000.00}'
```

### DELETE - Delete order
```bash
curl -X DELETE http://localhost:8090/api/orders/1
```

## Logs and Additional Endpoints

### Export logs from GrayLog to CSV
```bash
curl http://localhost:8090/api/logs/export
```

### Export logs for the last 6 hours
```bash
curl "http://localhost:8090/api/logs/export?hours=6"
```

### Get mock logs (test data)
```bash
curl http://localhost:8090/api/logs/mock-export
```

### Get MIREA logo
```bash
curl http://localhost:8090/api/mirea-logo -o mirea_logo.png
```

## Actuator (Metrics and Monitoring)

### Health check
```bash
curl http://localhost:8090/actuator/health
```

### Prometheus metrics
```bash
curl http://localhost:8090/actuator/prometheus
```

### Application info
```bash
curl http://localhost:8090/actuator/info
```

### All metrics
```bash
curl http://localhost:8090/actuator/metrics
```

## Batch Data Creation for Testing

### Create 5 users
```bash
for i in {1..5}; do
  curl -s -X POST http://localhost:8090/api/users \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"user$i\",\"email\":\"user$i@mirea.ru\",\"firstName\":\"Имя$i\",\"lastName\":\"Фамилия$i\"}"
  echo ""
done
```

### Create 3 products
```bash
curl -X POST http://localhost:8090/api/products -H "Content-Type: application/json" \
  -d '{"name":"Мышь","description":"Беспроводная мышь","price":1500.00,"stock":50}'

curl -X POST http://localhost:8090/api/products -H "Content-Type: application/json" \
  -d '{"name":"Монитор","description":"4K монитор 27 дюймов","price":25000.00,"stock":10}'

curl -X POST http://localhost:8090/api/products -H "Content-Type: application/json" \
  -d '{"name":"Наушники","description":"Игровые наушники","price":3500.00,"stock":20}'
```

### Create order with multiple products
```bash
curl -X POST http://localhost:8090/api/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"productIds":[1,2,3],"totalAmount":30000.00}'
```

## Quick Test Script

Run all basic operations:

```bash
#!/bin/bash

echo "Creating user..."
USER_ID=$(curl -s -X POST http://localhost:8090/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@mirea.ru","firstName":"Test","lastName":"User"}' \
  | grep -o '"id":[0-9]*' | cut -d: -f2)

echo "User created with ID: $USER_ID"

echo "Creating product..."
PRODUCT_ID=$(curl -s -X POST http://localhost:8090/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Product","description":"Test","price":1000.00,"stock":10}' \
  | grep -o '"id":[0-9]*' | cut -d: -f2)

echo "Product created with ID: $PRODUCT_ID"

echo "Creating order..."
curl -X POST http://localhost:8090/api/orders \
  -H "Content-Type: application/json" \
  -d "{\"userId\":$USER_ID,\"productIds\":[$PRODUCT_ID],\"totalAmount\":1000.00}"

echo "Getting all users..."
curl http://localhost:8090/api/users

echo "Exporting logs..."
curl http://localhost:8090/api/logs/export
```
