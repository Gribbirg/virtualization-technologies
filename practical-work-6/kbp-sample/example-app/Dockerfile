FROM node:20-alpine

WORKDIR /app

COPY server.js package.json /app/

RUN npm install

CMD node /app/server.js