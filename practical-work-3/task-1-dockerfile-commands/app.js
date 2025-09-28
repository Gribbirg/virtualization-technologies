const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const APP_NAME = process.env.APP_NAME || 'docker-demo';

app.use(express.json());

app.get('/', (req, res) => {
    res.json({
        message: `Welcome to ${APP_NAME}!`,
        environment: process.env.NODE_ENV,
        port: PORT,
        dockerCommands: [
            'FROM', 'RUN', 'LABEL', 'CMD', 'EXPOSE',
            'ENV', 'ADD', 'COPY', 'ENTRYPOINT',
            'VOLUME', 'USER', 'WORKDIR', 'ONBUILD'
        ]
    });
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/files', (req, res) => {
    try {
        const downloadsDir = '/app/downloads';
        const files = fs.existsSync(downloadsDir) ? fs.readdirSync(downloadsDir) : [];
        res.json({
            downloads: files,
            dataVolume: fs.existsSync('/app/data') ? 'mounted' : 'not mounted'
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`${APP_NAME} is running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV}`);
    console.log('All Docker commands demonstrated in Dockerfile!');
});

process.on('SIGTERM', () => {
    console.log('Received SIGTERM, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('Received SIGINT, shutting down gracefully');
    process.exit(0);
});