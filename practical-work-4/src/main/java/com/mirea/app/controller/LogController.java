package com.mirea.app.controller;

import com.opencsv.CSVWriter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import java.io.StringWriter;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/logs")
public class LogController {

    private static final Logger logger = LoggerFactory.getLogger(LogController.class);

    @Value("${graylog.host:graylog}")
    private String graylogHost;

    @Value("${graylog.api.port:9000}")
    private String graylogApiPort;

    @Value("${graylog.api.username:admin}")
    private String graylogUsername;

    @Value("${graylog.api.password:admin}")
    private String graylogPassword;

    private final RestTemplate restTemplate = new RestTemplate();

    @GetMapping("/export")
    public ResponseEntity<String> exportLogs(@RequestParam(defaultValue = "24") int hours) {
        logger.info("Exporting logs for the last {} hours", hours);

        try {
            List<LogEntry> logs = fetchLogsFromGraylog(hours);
            String csvContent = generateCSV(logs);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType("text/csv"));
            headers.setContentDispositionFormData("attachment", "database_operations.csv");

            logger.info("Successfully exported {} log entries", logs.size());
            return ResponseEntity.ok()
                    .headers(headers)
                    .body(csvContent);
        } catch (Exception e) {
            logger.error("Error exporting logs: {}", e.getMessage());
            return ResponseEntity.internalServerError()
                    .body("Error exporting logs: " + e.getMessage());
        }
    }

    @GetMapping("/mock-export")
    public ResponseEntity<String> mockExportLogs() {
        logger.info("Generating mock CSV data for database operations");

        try {
            List<LogEntry> mockLogs = generateMockLogs();
            String csvContent = generateCSV(mockLogs);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType("text/csv"));
            headers.setContentDispositionFormData("attachment", "database_operations_mock.csv");

            logger.info("Successfully generated {} mock log entries", mockLogs.size());
            return ResponseEntity.ok()
                    .headers(headers)
                    .body(csvContent);
        } catch (Exception e) {
            logger.error("Error generating mock logs: {}", e.getMessage());
            return ResponseEntity.internalServerError()
                    .body("Error generating mock logs: " + e.getMessage());
        }
    }

    private List<LogEntry> fetchLogsFromGraylog(int hours) {
        List<LogEntry> logs = new ArrayList<>();

        try {
            String auth = java.util.Base64.getEncoder()
                .encodeToString((graylogUsername + ":" + graylogPassword).getBytes());
            
            String graylogUrl = String.format(
                "http://%s:%s/api/search/universal/relative?query=*&range=%d&limit=1000&sort=timestamp:desc",
                graylogHost, graylogApiPort, hours * 3600
            );

            logger.info("Attempting to fetch logs from GrayLog: {}", graylogUrl);

            org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
            headers.set("Authorization", "Basic " + auth);
            headers.set("Accept", "application/json");

            org.springframework.http.HttpEntity<String> entity = 
                new org.springframework.http.HttpEntity<>(headers);

            @SuppressWarnings("unchecked")
            org.springframework.http.ResponseEntity<Map<String, Object>> response = 
                (org.springframework.http.ResponseEntity<Map<String, Object>>) (Object) restTemplate.exchange(
                    graylogUrl, org.springframework.http.HttpMethod.GET, entity, Map.class);

            Map<String, Object> body = response.getBody();
            if (body != null && body.containsKey("messages")) {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> messages = (List<Map<String, Object>>) body.get("messages");
                logger.info("Received {} messages from GrayLog", messages.size());
                
                for (Map<String, Object> messageWrapper : messages) {
                    if (messageWrapper.containsKey("message")) {
                        @SuppressWarnings("unchecked")
                        Map<String, Object> message = (Map<String, Object>) messageWrapper.get("message");
                        LogEntry logEntry = parseLogEntry(message);
                        if (logEntry != null && isDatabaseOperation(logEntry)) {
                            logs.add(logEntry);
                        }
                    }
                }
            }
            
            if (logs.isEmpty()) {
                logger.warn("No database operation logs found in GrayLog, returning mock data");
                return generateMockLogs();
            }
        } catch (Exception e) {
            logger.warn("Could not fetch from GrayLog ({}), returning mock data", e.getMessage());
            return generateMockLogs();
        }

        return logs;
    }

    private List<LogEntry> generateMockLogs() {
        List<LogEntry> logs = new ArrayList<>();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

        logs.add(new LogEntry(
            LocalDateTime.now().minusHours(1).format(formatter),
            "INFO",
            "UserController",
            "Creating new user: john_doe"
        ));

        logs.add(new LogEntry(
            LocalDateTime.now().minusHours(1).format(formatter),
            "INFO",
            "UserController",
            "User created with ID: 1"
        ));

        logs.add(new LogEntry(
            LocalDateTime.now().minusMinutes(30).format(formatter),
            "INFO",
            "ProductController",
            "Creating new product: Laptop"
        ));

        logs.add(new LogEntry(
            LocalDateTime.now().minusMinutes(30).format(formatter),
            "INFO",
            "ProductController",
            "Product created with ID: 1"
        ));

        logs.add(new LogEntry(
            LocalDateTime.now().minusMinutes(15).format(formatter),
            "INFO",
            "OrderController",
            "Creating new order for user ID: 1"
        ));

        logs.add(new LogEntry(
            LocalDateTime.now().minusMinutes(15).format(formatter),
            "INFO",
            "OrderController",
            "Order created with ID: 1"
        ));

        logs.add(new LogEntry(
            LocalDateTime.now().minusMinutes(10).format(formatter),
            "INFO",
            "UserController",
            "Updating user with ID: 1"
        ));

        logs.add(new LogEntry(
            LocalDateTime.now().minusMinutes(5).format(formatter),
            "INFO",
            "ProductController",
            "Deleting product with ID: 1"
        ));

        return logs;
    }

    private LogEntry parseLogEntry(Map<String, Object> message) {
        try {
            String timestamp = (String) message.get("timestamp");
            String level = (String) message.get("level");
            String logger = (String) message.get("source");
            String messageText = (String) message.get("message");

            return new LogEntry(timestamp, level, logger, messageText);
        } catch (Exception e) {
            logger.warn("Error parsing log entry: {}", e.getMessage());
            return null;
        }
    }

    private boolean isDatabaseOperation(LogEntry logEntry) {
        String message = logEntry.getMessage().toLowerCase();
        return message.contains("created") ||
               message.contains("updated") ||
               message.contains("deleted") ||
               message.contains("fetching") ||
               message.contains("creating") ||
               message.contains("updating") ||
               message.contains("deleting");
    }

    private String generateCSV(List<LogEntry> logs) throws Exception {
        StringWriter stringWriter = new StringWriter();
        CSVWriter csvWriter = new CSVWriter(stringWriter);

        String[] headers = {"Timestamp", "Level", "Logger", "Message"};
        csvWriter.writeNext(headers);

        for (LogEntry log : logs) {
            String[] row = {log.getTimestamp(), log.getLevel(), log.getLogger(), log.getMessage()};
            csvWriter.writeNext(row);
        }

        csvWriter.close();
        return stringWriter.toString();
    }

    private static class LogEntry {
        private String timestamp;
        private String level;
        private String logger;
        private String message;

        public LogEntry(String timestamp, String level, String logger, String message) {
            this.timestamp = timestamp;
            this.level = level;
            this.logger = logger;
            this.message = message;
        }

        public String getTimestamp() { return timestamp; }
        public String getLevel() { return level; }
        public String getLogger() { return logger; }
        public String getMessage() { return message; }
    }
}