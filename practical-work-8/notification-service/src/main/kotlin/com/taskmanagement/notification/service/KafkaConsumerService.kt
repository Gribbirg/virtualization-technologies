package com.taskmanagement.notification.service

import com.taskmanagement.notification.dto.KafkaEvent
import io.micrometer.core.instrument.Counter
import io.micrometer.core.instrument.MeterRegistry
import org.slf4j.LoggerFactory
import org.springframework.kafka.annotation.KafkaListener
import org.springframework.kafka.annotation.RetryableTopic
import org.springframework.kafka.support.KafkaHeaders
import org.springframework.messaging.handler.annotation.Header
import org.springframework.messaging.handler.annotation.Payload
import org.springframework.retry.annotation.Backoff
import org.springframework.stereotype.Service

@Service
class KafkaConsumerService(
    private val notificationService: NotificationService,
    private val meterRegistry: MeterRegistry
) {
    
    private val logger = LoggerFactory.getLogger(KafkaConsumerService::class.java)
    
    private val eventsConsumedCounter: Counter = Counter.builder("kafka_events_consumed_total")
        .description("Total number of Kafka events consumed")
        .tag("service", "notification-service")
        .register(meterRegistry)
    
    private val eventsFailedCounter: Counter = Counter.builder("kafka_events_failed_total")
        .description("Total number of failed Kafka event processing")
        .tag("service", "notification-service")
        .register(meterRegistry)
    
    @RetryableTopic(
        attempts = "3",
        backoff = Backoff(delay = 1000, multiplier = 2.0),
        dltTopicSuffix = "-dlt"
    )
    @KafkaListener(
        topics = ["auth-events", "task-events"],
        groupId = "notification-service-group"
    )
    fun consumeEvent(
        @Payload event: KafkaEvent,
        @Header(KafkaHeaders.RECEIVED_TOPIC) topic: String
    ) {
        try {
            logger.info("[NOTIFICATION-SERVICE] [INFO] Kafka event consumed: ${event.eventType} - User: ${event.userId} - Topic: $topic")
            
            notificationService.createNotification(event)
            eventsConsumedCounter.increment()
            
        } catch (ex: Exception) {
            logger.error("[NOTIFICATION-SERVICE] [ERROR] Failed to process Kafka event: ${ex.message}", ex)
            eventsFailedCounter.increment()
            throw ex
        }
    }
}

