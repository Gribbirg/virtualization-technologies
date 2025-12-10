package com.taskmanagement.task.service

import org.slf4j.LoggerFactory
import org.springframework.kafka.core.KafkaTemplate
import org.springframework.stereotype.Service
import java.time.Instant

@Service
class KafkaProducerService(
    private val kafkaTemplate: KafkaTemplate<String, Any>
) {
    private val logger = LoggerFactory.getLogger(javaClass)
    private val topic = "task-events"

    fun publishTaskCreated(taskId: Long, userId: Long, title: String, status: String) {
        val event = mapOf(
            "eventType" to "TASK_CREATED",
            "taskId" to taskId,
            "userId" to userId,
            "title" to title,
            "status" to status,
            "timestamp" to Instant.now().toString()
        )
        publishEvent(event)
    }

    fun publishTaskUpdated(taskId: Long, userId: Long, title: String, oldStatus: String, newStatus: String) {
        val event = mapOf(
            "eventType" to "TASK_UPDATED",
            "taskId" to taskId,
            "userId" to userId,
            "title" to title,
            "oldStatus" to oldStatus,
            "newStatus" to newStatus,
            "timestamp" to Instant.now().toString()
        )
        publishEvent(event)
    }

    fun publishTaskDeleted(taskId: Long, userId: Long) {
        val event = mapOf(
            "eventType" to "TASK_DELETED",
            "taskId" to taskId,
            "userId" to userId,
            "timestamp" to Instant.now().toString()
        )
        publishEvent(event)
    }

    fun publishTaskCompleted(taskId: Long, userId: Long, title: String) {
        val event = mapOf(
            "eventType" to "TASK_COMPLETED",
            "taskId" to taskId,
            "userId" to userId,
            "title" to title,
            "timestamp" to Instant.now().toString()
        )
        publishEvent(event)
    }

    private fun publishEvent(event: Map<String, Any>) {
        try {
            kafkaTemplate.send(topic, event)
            logger.info("Published event to Kafka: ${event["eventType"]}")
        } catch (e: Exception) {
            logger.error("Failed to publish event to Kafka: ${e.message}", e)
        }
    }
}

