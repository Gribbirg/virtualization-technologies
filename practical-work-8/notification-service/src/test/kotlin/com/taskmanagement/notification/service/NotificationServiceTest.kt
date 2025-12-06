package com.taskmanagement.notification.service

import com.taskmanagement.notification.dto.KafkaEvent
import com.taskmanagement.notification.entity.Notification
import com.taskmanagement.notification.exception.NotificationNotFoundException
import com.taskmanagement.notification.repository.NotificationRepository
import io.micrometer.core.instrument.MeterRegistry
import io.micrometer.core.instrument.simple.SimpleMeterRegistry
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.PageRequest
import java.time.Instant
import java.util.*

class NotificationServiceTest {
    
    private lateinit var notificationRepository: NotificationRepository
    private lateinit var meterRegistry: MeterRegistry
    private lateinit var notificationService: NotificationService
    
    @BeforeEach
    fun setup() {
        notificationRepository = mockk()
        meterRegistry = SimpleMeterRegistry()
        notificationService = NotificationService(notificationRepository, meterRegistry)
    }
    
    @Test
    fun `createNotification should create notification successfully`() {
        val event = KafkaEvent(
            eventType = "TASK_CREATED",
            userId = 1L,
            metadata = mapOf("title" to "Test Task")
        )
        
        val notification = Notification(
            id = 1L,
            userId = 1L,
            eventType = "TASK_CREATED",
            message = "New task created: Test Task",
            metadata = event.metadata
        )
        
        every { notificationRepository.save(any()) } returns notification
        
        val result = notificationService.createNotification(event)
        
        assertNotNull(result)
        assertEquals(1L, result.id)
        assertEquals(1L, result.userId)
        assertEquals("TASK_CREATED", result.eventType)
        
        verify { notificationRepository.save(any()) }
    }
    
    @Test
    fun `getNotifications should return user notifications`() {
        val notification = Notification(
            id = 1L,
            userId = 1L,
            eventType = "TASK_CREATED",
            message = "Test notification"
        )
        
        val page = PageImpl(listOf(notification))
        
        every { notificationRepository.findByUserId(1L, any()) } returns page
        
        val result = notificationService.getNotifications(1L, false, 0, 20)
        
        assertEquals(1, result.content.size)
        assertEquals(1L, result.content[0].id)
        
        verify { notificationRepository.findByUserId(1L, any()) }
    }
    
    @Test
    fun `getNotifications with unreadOnly should return only unread notifications`() {
        val notification = Notification(
            id = 1L,
            userId = 1L,
            eventType = "TASK_CREATED",
            message = "Test notification",
            readAt = null
        )
        
        val page = PageImpl(listOf(notification))
        
        every { notificationRepository.findByUserIdAndReadAtIsNull(1L, any()) } returns page
        
        val result = notificationService.getNotifications(1L, true, 0, 20)
        
        assertEquals(1, result.content.size)
        assertNull(result.content[0].readAt)
        
        verify { notificationRepository.findByUserIdAndReadAtIsNull(1L, any()) }
    }
    
    @Test
    fun `markAsRead should update readAt timestamp`() {
        val notification = Notification(
            id = 1L,
            userId = 1L,
            eventType = "TASK_CREATED",
            message = "Test notification",
            readAt = null
        )
        
        every { notificationRepository.findById(1L) } returns Optional.of(notification)
        every { notificationRepository.save(any()) } returns notification.copy(readAt = Instant.now())
        
        val result = notificationService.markAsRead(1L, 1L)
        
        assertNotNull(result)
        
        verify { notificationRepository.findById(1L) }
        verify { notificationRepository.save(any()) }
    }
    
    @Test
    fun `markAsRead should throw exception when notification not found`() {
        every { notificationRepository.findById(1L) } returns Optional.empty()
        
        assertThrows<NotificationNotFoundException> {
            notificationService.markAsRead(1L, 1L)
        }
    }
    
    @Test
    fun `markAllAsRead should mark all user notifications as read`() {
        every { notificationRepository.markAllAsReadByUserId(1L) } returns 5
        
        val result = notificationService.markAllAsRead(1L)
        
        assertEquals("All notifications marked as read", result.message)
        assertEquals(5, result.count)
        
        verify { notificationRepository.markAllAsReadByUserId(1L) }
    }
    
    @Test
    fun `getUnreadCount should return correct count`() {
        every { notificationRepository.countByUserIdAndReadAtIsNull(1L) } returns 3L
        
        val result = notificationService.getUnreadCount(1L)
        
        assertEquals(1L, result.userId)
        assertEquals(3L, result.unreadCount)
        
        verify { notificationRepository.countByUserIdAndReadAtIsNull(1L) }
    }
    
    @Test
    fun `deleteNotification should delete notification successfully`() {
        every { notificationRepository.existsByIdAndUserId(1L, 1L) } returns true
        every { notificationRepository.deleteById(1L) } returns Unit
        
        notificationService.deleteNotification(1L, 1L)
        
        verify { notificationRepository.existsByIdAndUserId(1L, 1L) }
        verify { notificationRepository.deleteById(1L) }
    }
    
    @Test
    fun `deleteNotification should throw exception when notification not found`() {
        every { notificationRepository.existsByIdAndUserId(1L, 1L) } returns false
        
        assertThrows<NotificationNotFoundException> {
            notificationService.deleteNotification(1L, 1L)
        }
    }
}

