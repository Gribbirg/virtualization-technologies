FROM gradle:8.14-jdk21 AS build

LABEL maintainer="Александр Грибков <student@mirea.ru>"
LABEL version="1.0"
LABEL description="Multi-stage Spring Boot application with PostgreSQL"

WORKDIR /app

COPY build.gradle.kts ./
COPY src src

RUN apt-get update && \
    apt-get install -y wget && \
    mkdir -p src/main/resources/static && \
    wget -O src/main/resources/static/MIREA_Gerb_Colour.png \
         https://www.mirea.ru/upload/medialibrary/80f/MIREA_Gerb_Colour.png && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN gradle build --no-daemon -x test

FROM eclipse-temurin:21-jre

WORKDIR /app

ENV DB_HOST=postgres
ENV DB_PORT=5432
ENV DB_NAME=mirea_db
ENV DB_USERNAME=mirea_user
ENV DB_PASSWORD=mirea_password

COPY --from=build /app/build/libs/*.jar app.jar
COPY --from=build /app/src/main/resources/static/MIREA_Gerb_Colour.png /app/static/

EXPOSE 8080

ONBUILD RUN echo "Сборка и запуск произведены. Автор: Александр Грибков"

ENTRYPOINT ["java", "-jar", "app.jar"]
