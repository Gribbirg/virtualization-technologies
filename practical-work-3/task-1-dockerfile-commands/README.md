# Task 1: Docker Commands Demo

This project demonstrates all 13 required Docker commands in a single Dockerfile.

## Docker Commands Used

1. **FROM** - Uses Node.js 18 slim base image
2. **LABEL** - Adds metadata (maintainer, version, description)
3. **ENV** - Sets environment variables (NODE_ENV, PORT, APP_NAME)
4. **WORKDIR** - Sets working directory to /app
5. **USER** - Creates and switches to non-root user 'appuser'
6. **COPY** - Copies package.json and application files
7. **RUN** - Installs dependencies, creates directories, sets permissions
8. **ADD** - Downloads Node.js README from GitHub URL
9. **VOLUME** - Creates mount point at /app/data
10. **EXPOSE** - Documents port 3000
11. **ONBUILD** - Adds triggers for child images
12. **ENTRYPOINT** - Sets node as main executable
13. **CMD** - Provides default argument (app.js)

## Build and Run

### Automated Testing (Recommended)
Run the automated test script that handles Colima startup, Docker build, testing, and cleanup:
```bash
./test-docker.sh
```

This script will:
- Start Colima Docker runtime
- Build the Docker image
- Run the container and test all endpoints
- Clean up containers, images, and stop Colima

### Manual Build and Run

### Build the image:
```bash
docker build -t docker-commands-demo .
```

### Run the container:
```bash
docker run -p 3000:3000 docker-commands-demo
```

### Run with volume mount:
```bash
docker run -p 3000:3000 -v $(pwd)/data:/app/data docker-commands-demo
```

## Test Endpoints

- `http://localhost:3000/` - Main info endpoint
- `http://localhost:3000/health` - Health check
- `http://localhost:3000/files` - List downloaded files and volume status

## Verification

The application will:
1. Start a web server on port 3000
2. Serve JSON responses showing Docker commands used
3. Display downloaded Node.js README via ADD command
4. Show volume mount status
5. Run as non-root user for security