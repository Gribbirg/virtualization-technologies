# Screenshots for Practical Work 3

This directory contains screenshots for the practical work report.

## Required Screenshots

### Task 1: Dockerfile Commands Demo

1. **Сборка Docker образа для задания 1** - Screenshot of `docker build` command execution for task 1
2. **Запуск контейнера задания 1** - Screenshot of `docker run` command for the Node.js container
3. **Тестирование эндпоинтов приложения задания 1** - Screenshot of testing endpoints (/, /health, /files)

### Task 2: Spring Boot + PostgreSQL

4. **Структура многоэтапного Dockerfile** - Screenshot showing the multi-stage Dockerfile structure
5. **Сборка образа через Docker Compose** - Screenshot of `docker-compose build` command execution
6. **Запуск контейнеров через Docker Compose** - Screenshot of `docker-compose up` showing both containers starting
7. **Тестирование POST запроса добавления элемента** - Screenshot of POST request to `/api/items`
8. **Тестирование GET запроса списка элементов** - Screenshot of GET request to `/api/items`
9. **Тестирование GET запроса герба МИРЭА** - Screenshot of GET request to `/api/mirea-logo` showing the image
10. **Проверка данных в PostgreSQL** - Screenshot of `docker exec` into postgres container and querying data
11. **Загрузка образа в DockerHub** - Screenshot of `docker push` command uploading to DockerHub

## Instructions

1. Run the test scripts:
   - `cd task-1-dockerfile-commands && ./test-docker.sh`
   - `cd task-2-spring-boot-app && ./test-docker.sh`

2. Take screenshots during execution at the appropriate moments

3. Save screenshots in this directory with descriptive names

4. Replace placeholders in the report with actual screenshot references

