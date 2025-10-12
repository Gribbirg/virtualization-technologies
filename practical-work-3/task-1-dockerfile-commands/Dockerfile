FROM node:18-slim

LABEL maintainer="Student Alexander Gribkov <gribkov.a.s@edu.mirea.ru>"
LABEL version="1.0"
LABEL description="Dockerfile demonstrating all Docker commands for Task 1"

ENV NODE_ENV=production
ENV PORT=3000
ENV APP_NAME="docker-commands-demo"

WORKDIR /app

RUN groupadd -r appuser && useradd -r -g appuser appuser

COPY package.json ./

RUN apt-get update && \
    apt-get install -y wget && \
    npm install --production && \
    mkdir -p /app/data /app/downloads && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ADD https://raw.githubusercontent.com/nodejs/node/main/README.md /app/downloads/node-readme.md

COPY . .

RUN chown -R appuser:appuser /app

USER appuser

VOLUME ["/app/data"]

EXPOSE $PORT

ONBUILD COPY . /app
ONBUILD RUN npm install

ENTRYPOINT ["node"]

CMD ["app.js"]