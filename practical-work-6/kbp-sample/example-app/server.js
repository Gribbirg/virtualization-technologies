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