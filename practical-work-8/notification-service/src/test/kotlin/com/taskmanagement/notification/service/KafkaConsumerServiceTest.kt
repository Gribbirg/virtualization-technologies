package com.taskmanagement.notification.service

import com.taskmanagement.notification.dto.KafkaEvent
import com.taskmanagement.notification.entity.Notification
import io.micrometer.core.instrument.simple.SimpleMeterRegistry
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows

class KafkaConsumerServiceTest {
    
    private lateinit var notificationService: NotificationService
    private lateinit var meterRegistry: SimpleMeterRegistry
    private lateinit var kafkaConsumerService: KafkaConsumerService
    
    @BeforeEach
    fun setup() {
        notificationService = mockk()
        meterRegistry = SimpleMeterRegistry()
        kafkaConsumerService = KafkaConsumerService(notificationService, meterRegistry)
    }
    
    @Test
    fun `consumeAuthEvent should create notification for USER_REGISTERED`() {
        val event = KafkaEvent(
            eventType = "USER_REGISTERED",
            userId = 1L,
            metadata = emptyMap()
        )
        
        val notification = Notification(
            id = 1L,
            userId = 1L,
            eventType = "USER_REGISTERED",
            message = "Welcome! Your account has been created successfully."
        )
        
        every { notificationService.createNotification(event) } returns notification
        
        kafkaConsumerService.consumeEvent(event, "auth-events")
        
        verify { notificationService.createNotification(event) }
    }
    
    @Test
    fun `consumeTaskEvent should create notification for TASK_CREATED`() {
        val event = KafkaEvent(
            eventType = "TASK_CREATED",
            userId = 1L,
            metadata = mapOf("title" to "Test Task")
        )
        
        val notification = Notification(
            id = 1L,
            userId = 1L,
            eventType = "TASK_CREATED",
            message = "New task created: Test Task"
        )
        
        every { notificationService.createNotification(event) } returns notification
        
        kafkaConsumerService.consumeEvent(event, "task-events")
        
        verify { notificationService.createNotification(event) }
    }
    
    @Test
    fun `consumeTaskEvent should create notification for TASK_UPDATED`() {
        val event = KafkaEvent(
            eventType = "TASK_UPDATED",
            userId = 1L,
            metadata = mapOf("title" to "Test Task", "newStatus" to "IN_PROGRESS")
        )
        
        val notification = Notification(
            id = 1L,
            userId = 1L,
            eventType = "TASK_UPDATED",
            message = "Task updated: Test Task - Status: IN_PROGRESS"
        )
        
        every { notificationService.createNotification(event) } returns notification
        
        kafkaConsumerService.consumeEvent(event, "task-events")
        
        verify { notificationService.createNotification(event) }
    }
    
    @Test
    fun `consumeTaskEvent should create notification for TASK_COMPLETED`() {
        val event = KafkaEvent(
            eventType = "TASK_COMPLETED",
            userId = 1L,
            metadata = mapOf("title" to "Test Task")
        )
        
        val notification = Notification(
            id = 1L,
            userId = 1L,
            eventType = "TASK_COMPLETED",
            message = "Task completed: Test Task ✓"
        )
        
        every { notificationService.createNotification(event) } returns notification
        
        kafkaConsumerService.consumeEvent(event, "task-events")
        
        verify { notificationService.createNotification(event) }
    }
    
    @Test
    fun `consumeInvalidEvent should handle gracefully and rethrow`() {
        val event = KafkaEvent(
            eventType = "INVALID_EVENT",
            userId = 1L,
            metadata = emptyMap()
        )
        
        every { notificationService.createNotification(event) } throws RuntimeException("Test error")
        
        assertThrows<RuntimeException> {
            kafkaConsumerService.consumeEvent(event, "test-events")
        }
        
        verify { notificationService.createNotification(event) }
    }
}

