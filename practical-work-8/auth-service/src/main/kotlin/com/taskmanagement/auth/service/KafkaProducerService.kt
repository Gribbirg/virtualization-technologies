package com.taskmanagement.auth.service

import com.taskmanagement.auth.dto.AuthEvent
import org.slf4j.LoggerFactory
import org.springframework.kafka.core.KafkaTemplate
import org.springframework.stereotype.Service

@Service
class KafkaProducerService(
    private val kafkaTemplate: KafkaTemplate<String, AuthEvent>
) {
    private val logger = LoggerFactory.getLogger(KafkaProducerService::class.java)
    private val topic = "auth-events"
    
    fun publishEvent(event: AuthEvent) {
        try {
            kafkaTemplate.send(topic, event.userId.toString(), event)
            logger.info("Published event: ${event.eventType} for user ${event.username}")
        } catch (ex: Exception) {
            logger.error("Failed to publish event: ${event.eventType}", ex)
        }
    }
}

