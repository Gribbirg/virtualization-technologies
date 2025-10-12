# Practical Work 3: Docker and Dockerfile

This directory contains all materials for Practical Work 3 on Docker containerization.

## Structure

```
practical-work-3/
├── task/                          # Assignment materials
│   ├── task.md                    # Task requirements
│   ├── theory.md                  # Theoretical background
│   ├── questions.md               # Questions for the report
│   └── criteria.md                # Grading criteria
├── task-1-dockerfile-commands/    # Task 1: Dockerfile with all 13 commands
│   ├── Dockerfile                 # Dockerfile demonstrating all commands
│   ├── app.js                     # Node.js application
│   ├── package.json               # Node.js dependencies
│   ├── test-docker.sh             # Automated test script
│   └── README.md                  # Task 1 documentation
├── task-2-spring-boot-app/        # Task 2: Spring Boot + PostgreSQL
│   ├── Dockerfile                 # Multi-stage Dockerfile
│   ├── docker-compose.yml         # Container orchestration
│   ├── build.gradle.kts           # Gradle build configuration
│   ├── src/                       # Java source code
│   ├── test-docker.sh             # Automated test script
│   └── README.md                  # Task 2 documentation
├── screenshots/                   # Screenshots for the report
│   └── README.md                  # Instructions for screenshots
└── report/                        # Final report
    ├── ПВКСП_Отчет3_ГрибковАС_ИКБО-16-22.md    # Markdown report
    └── ПВКСП_Отчет3_ГрибковАС_ИКБО-16-22.docx  # Word report
```

## Tasks Completed

### Task 1: Dockerfile Commands Demonstration
✅ Created Dockerfile using all 13 required commands:
- FROM, RUN, LABEL, CMD, EXPOSE, ENV, ADD, COPY, ENTRYPOINT, VOLUME, USER, WORKDIR, ONBUILD

### Task 2: Spring Boot Web Application
✅ Developed Spring Boot application with:
- PostgreSQL database integration
- Three API endpoints (POST /api/items, GET /api/items, GET /api/mirea-logo)
- Multi-stage Dockerfile for optimized build
- Docker Compose orchestration
- Downloaded MIREA logo using wget during build
- Environment variables for database configuration

## Running the Applications

### Task 1
```bash
cd task-1-dockerfile-commands
./test-docker.sh
```

### Task 2
```bash
cd task-2-spring-boot-app
./test-docker.sh
```

## Report

The report is available in two formats:
- **Markdown**: `report/ПВКСП_Отчет3_ГрибковАС_ИКБО-16-22.md`
- **Word**: `report/ПВКСП_Отчет3_ГрибковАС_ИКБО-16-22.docx`

The report includes:
- Goals and objectives
- Detailed description of completed tasks
- Code listings (Dockerfiles, docker-compose.yml)
- Placeholders for screenshots
- Answers to theoretical questions
- References

## Screenshots

Screenshots need to be taken and placed in the `screenshots/` directory. See `screenshots/README.md` for the list of required screenshots.

## Conversion to Word

The Word document was generated from Markdown using Pandoc:
```bash
cd report
pandoc ПВКСП_Отчет3_ГрибковАС_ИКБО-16-22.md \
  -o ПВКСП_Отчет3_ГрибковАС_ИКБО-16-22.docx \
  --reference-doc=../../common/style_source.docx
```

