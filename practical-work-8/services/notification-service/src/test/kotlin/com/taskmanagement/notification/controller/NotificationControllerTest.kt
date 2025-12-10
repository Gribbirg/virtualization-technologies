package com.taskmanagement.notification.controller

import com.taskmanagement.notification.dto.*
import com.taskmanagement.notification.security.AuthenticationFilter
import com.taskmanagement.notification.service.NotificationService
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import jakarta.servlet.http.HttpServletRequest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.time.Instant

class NotificationControllerTest {
    
    private lateinit var notificationService: NotificationService
    private lateinit var notificationController: NotificationController
    private lateinit var request: HttpServletRequest
    
    @BeforeEach
    fun setup() {
        notificationService = mockk()
        notificationController = NotificationController(notificationService)
        request = mockk()
        
        every { request.getAttribute(AuthenticationFilter.USER_INFO_ATTRIBUTE) } returns UserInfo(1L, "testuser")
        every { request.remoteAddr } returns "127.0.0.1"
    }
    
    @Test
    fun `getNotifications should return notifications`() {
        val response = NotificationPageResponse(
            content = listOf(
                NotificationResponse(
                    id = 1L,
                    userId = 1L,
                    eventType = "TASK_CREATED",
                    message = "Test notification",
                    metadata = null,
                    createdAt = Instant.now(),
                    readAt = null
                )
            ),
            page = 0,
            size = 20,
            totalElements = 1,
            totalPages = 1
        )
        
        every { notificationService.getNotifications(1L, false, 0, 20) } returns response
        
        val result = notificationController.getNotifications(false, 0, 20, request)
        
        assertNotNull(result)
        assertEquals(1, result.content.size)
        
        verify { notificationService.getNotifications(1L, false, 0, 20) }
    }
    
    @Test
    fun `getNotificationById should return notification`() {
        val response = NotificationResponse(
            id = 1L,
            userId = 1L,
            eventType = "TASK_CREATED",
            message = "Test notification",
            metadata = null,
            createdAt = Instant.now(),
            readAt = null
        )
        
        every { notificationService.getNotificationById(1L, 1L) } returns response
        
        val result = notificationController.getNotificationById(1L, request)
        
        assertNotNull(result)
        assertEquals(1L, result.id)
        
        verify { notificationService.getNotificationById(1L, 1L) }
    }
    
    @Test
    fun `markAsRead should mark notification as read`() {
        val response = NotificationResponse(
            id = 1L,
            userId = 1L,
            eventType = "TASK_CREATED",
            message = "Test notification",
            metadata = null,
            createdAt = Instant.now(),
            readAt = Instant.now()
        )
        
        every { notificationService.markAsRead(1L, 1L) } returns response
        
        val result = notificationController.markAsRead(1L, request)
        
        assertNotNull(result)
        assertNotNull(result.readAt)
        
        verify { notificationService.markAsRead(1L, 1L) }
    }
    
    @Test
    fun `markAllAsRead should mark all notifications as read`() {
        val response = MarkAllReadResponse("All notifications marked as read", 5)
        
        every { notificationService.markAllAsRead(1L) } returns response
        
        val result = notificationController.markAllAsRead(request)
        
        assertNotNull(result)
        assertEquals(5, result.count)
        
        verify { notificationService.markAllAsRead(1L) }
    }
    
    @Test
    fun `getUnreadCount should return unread count`() {
        val response = UnreadCountResponse(1L, 3L)
        
        every { notificationService.getUnreadCount(1L) } returns response
        
        val result = notificationController.getUnreadCount(request)
        
        assertNotNull(result)
        assertEquals(3L, result.unreadCount)
        
        verify { notificationService.getUnreadCount(1L) }
    }
    
    @Test
    fun `deleteNotification should delete notification`() {
        every { notificationService.deleteNotification(1L, 1L) } returns Unit
        
        notificationController.deleteNotification(1L, request)
        
        verify { notificationService.deleteNotification(1L, 1L) }
    }
}

