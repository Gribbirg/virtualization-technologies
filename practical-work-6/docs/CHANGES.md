# Изменения в коде Frontend приложения

**Автор:** Грибков А.С. ИКБО-16-22
**Дата:** 16.11.2025

---

## Проблема

Исходное приложение `kbp-sample/example-app/server.js` было написано для:
1. Redis v2/v3 API (callback-based)
2. Локального подключения к Redis на `127.0.0.1`
3. Без аутентификации

В Kubernetes окружении с Redis StatefulSet требовалось:
1. Использовать Redis v4+ API (async/await)
2. Подключаться к Redis Master через DNS
3. Использовать пароль из Kubernetes Secret

---

## Изменения в `server.js`

### 1. Добавление чтения пароля Redis из Secret

**До:**
```javascript
const client = redis.createClient({
    'host': '127.0.0.1'
});
```

**После:**
```javascript
const fs = require('fs');

let redisPassword = '';
try {
    redisPassword = fs.readFileSync('/etc/redis-passwd/passwd', 'utf8').trim();
} catch (err) {
    console.log('Warning: Could not read Redis password from /etc/redis-passwd/passwd');
}
```

**Причина:**
Redis в StatefulSet настроен с паролем, который хранится в Kubernetes Secret `redis-passwd` и монтируется в под по пути `/etc/redis-passwd/passwd`.

---

### 2. Настройка подключения к Redis Master через DNS

**До:**
```javascript
const client = redis.createClient({
    'host': '127.0.0.1'
});
```

**После:**
```javascript
const redisHost = process.env.REDIS_HOST || 'redis-0.redis.default.svc.cluster.local';
const redisPort = parseInt(process.env.REDIS_PORT_6379_TCP_PORT || '6379');

const client = redis.createClient({
    socket: {
        host: redisHost,
        port: redisPort
    },
    password: redisPassword
});
```

**Причина:**
- В Kubernetes для записи в Redis нужно подключаться к Master (redis-0)
- StatefulSet создает DNS записи вида: `<pod-name>.<service-name>.<namespace>.svc.cluster.local`
- Для нашего случая: `redis-0.redis.default.svc.cluster.local`
- Переменная окружения `REDIS_PORT` содержит `tcp://IP:PORT`, поэтому используется `REDIS_PORT_6379_TCP_PORT`

---

### 3. Обновление API Redis с callback на async/await

**До (Redis v2/v3 с callbacks):**
```javascript
const requestHandler = (request, response) => {
    const key = 'journal-key';
    client.get(key, (err, value) => {
        if (err) {
            response.writeHead(500);
            response.end(err.toString());
            return;
        }
        var journals = [];
        if (value) {
            journals = JSON.parse(value);
        }
        // ... обработка GET/POST
    });
}
```

**После (Redis v4+ с async/await):**
```javascript
const requestHandler = async (request, response) => {
    const key = 'journal-key';

    try {
        const value = await client.get(key);
        var journals = [];
        if (value) {
            journals = JSON.parse(value);
        }

        if (request.method == 'GET') {
            response.writeHead(200, {'Content-Type': 'application/json'});
            response.end(JSON.stringify(journals));
        }

        if (request.method == 'POST') {
            let body = [];
            request.on('data', (chunk) => {
                body.push(chunk);
            }).on('end', async () => {
                try {
                    body = Buffer.concat(body).toString();
                    const msg = JSON.parse(body);
                    journals.push(msg);
                    await client.set(key, JSON.stringify(journals));
                    response.writeHead(200, {'Content-Type': 'application/json'});
                    response.end(JSON.stringify(journals));
                } catch (err) {
                    response.writeHead(500);
                    response.end(err.toString());
                }
            });
        }
    } catch (err) {
        response.writeHead(500);
        response.end(err.toString());
    }
}
```

**Причина:**
Redis v4+ использует промисы вместо callback'ов. Требуется:
- Добавить `async` к функции `requestHandler`
- Использовать `await` для операций с Redis
- Обернуть код в `try/catch` для обработки ошибок

---

### 4. Добавление обязательного вызова `client.connect()`

**До:**
```javascript
const server = http.createServer(requestHandler);

server.listen(port, (err) => {
    if (err) {
        return console.log('could not start server', err);
    }
    console.log('api server up and running.');
})
```

**После:**
```javascript
const server = http.createServer(requestHandler);

async function startServer() {
    try {
        console.log(`Connecting to Redis at ${redisHost}:${redisPort}...`);
        await client.connect();
        console.log('Connected to Redis successfully');

        server.listen(port, (err) => {
            if (err) {
                return console.log('could not start server', err);
            }
            console.log('api server up and running.');
        });
    } catch (err) {
        console.log('Failed to connect to Redis:', err.message);
        console.log('Full error:', err);
        process.exit(1);
    }
}

startServer();
```

**Причина:**
В Redis v4+ клиент нужно **явно подключить** через `await client.connect()` перед использованием. Без этого все операции вернут ошибку `ClientClosedError`.

---

### 5. Добавление обработчика ошибок Redis

**Добавлено:**
```javascript
client.on('error', (err) => console.log('Redis Client Error', err));
```

**Причина:**
Для отладки и логирования проблем с подключением к Redis.

---

## Изменения в `Dockerfile`

**До:**
```dockerfile
COPY server.js /app
RUN npm install redis
```

**После:**
```dockerfile
COPY server.js package.json /app/
RUN npm install
```

**Причина:**
Используем `package.json` для фиксации версии redis v4.6.14 вместо установки последней версии.

---

## Итоговый полный файл `server.js`

```javascript
const http = require('http');
const redis = require('redis');
const fs = require('fs');

const redisHost = process.env.REDIS_HOST || 'redis-0.redis.default.svc.cluster.local';
const redisPort = parseInt(process.env.REDIS_PORT_6379_TCP_PORT || '6379');

let redisPassword = '';
try {
    redisPassword = fs.readFileSync('/etc/redis-passwd/passwd', 'utf8').trim();
} catch (err) {
    console.log('Warning: Could not read Redis password from /etc/redis-passwd/passwd');
}

const client = redis.createClient({
    socket: {
        host: redisHost,
        port: redisPort
    },
    password: redisPassword
});

client.on('error', (err) => console.log('Redis Client Error', err));

const port = 8080;

const requestHandler = async (request, response) => {
    console.log(request.url);
    if (!request.url.startsWith('/api')) {
        response.writeHead(404);
        response.end('Not found');
        return;
    }
    if (request.method != 'GET' && request.method != 'POST') {
        response.writeHead(400);
        response.end('Unsupported method.');
        return;
    }

    const key = 'journal-key';

    try {
        const value = await client.get(key);
        var journals = [];
        if (value) {
            journals = JSON.parse(value);
        }

        if (request.method == 'GET') {
            response.writeHead(200, {'Content-Type': 'application/json'});
            response.end(JSON.stringify(journals));
        }

        if (request.method == 'POST') {
            let body = [];
            request.on('data', (chunk) => {
                body.push(chunk);
            }).on('end', async () => {
                try {
                    body = Buffer.concat(body).toString();
                    const msg = JSON.parse(body);
                    journals.push(msg);
                    await client.set(key, JSON.stringify(journals));
                    response.writeHead(200, {'Content-Type': 'application/json'});
                    response.end(JSON.stringify(journals));
                } catch (err) {
                    response.writeHead(500);
                    response.end(err.toString());
                }
            });
        }
    } catch (err) {
        response.writeHead(500);
        response.end(err.toString());
    }
}

const server = http.createServer(requestHandler);

async function startServer() {
    try {
        console.log(`Connecting to Redis at ${redisHost}:${redisPort}...`);
        await client.connect();
        console.log('Connected to Redis successfully');

        server.listen(port, (err) => {
            if (err) {
                return console.log('could not start server', err);
            }
            console.log('api server up and running.');
        });
    } catch (err) {
        console.log('Failed to connect to Redis:', err.message);
        console.log('Full error:', err);
        process.exit(1);
    }
}

startServer();
```

---

## Проверка работоспособности

После внесения изменений:

1. **Сборка образа:**
   ```bash
   docker build -t gribkov/journal-server:v1 kbp-sample/example-app/
   ```

2. **Загрузка в Minikube:**
   ```bash
   minikube image load gribkov/journal-server:v1
   ```

3. **Перезапуск деплоймента:**
   ```bash
   kubectl rollout restart deployment/frontend
   ```

4. **Проверка логов:**
   ```bash
   kubectl logs -l app=frontend
   ```

   Ожидаемый вывод:
   ```
   Connecting to Redis at redis-0.redis.default.svc.cluster.local:6379...
   Connected to Redis successfully
   api server up and running.
   ```

5. **Тестирование API:**
   ```bash
   # В отдельном терминале
   kubectl port-forward svc/frontend 8080:8080

   # В другом терминале
   curl http://localhost:8080/api/
   # Вывод: []

   curl -X POST http://localhost:8080/api/ -H "Content-Type: application/json" -d '{"text":"Тест"}'
   # Вывод: [{"text":"Тест"}]
   ```

---

## Ключевые моменты для демонстрации

1. ✅ Приложение подключается к Redis Master через Kubernetes DNS
2. ✅ Использует пароль из Secret для аутентификации
3. ✅ Поддерживает GET и POST запросы
4. ✅ Данные сохраняются в Redis и персистентны
5. ✅ Логи показывают успешное подключение к Redis

---

**Все изменения необходимы для корректной работы приложения в Kubernetes с Redis StatefulSet.**
