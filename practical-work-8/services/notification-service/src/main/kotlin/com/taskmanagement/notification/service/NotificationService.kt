package com.taskmanagement.notification.service

import com.taskmanagement.notification.dto.*
import com.taskmanagement.notification.entity.Notification
import com.taskmanagement.notification.exception.NotificationNotFoundException
import com.taskmanagement.notification.repository.NotificationRepository
import io.micrometer.core.instrument.Counter
import io.micrometer.core.instrument.Gauge
import io.micrometer.core.instrument.MeterRegistry
import org.slf4j.LoggerFactory
import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant

@Service
class NotificationService(
    private val notificationRepository: NotificationRepository,
    private val meterRegistry: MeterRegistry
) {
    
    private val logger = LoggerFactory.getLogger(NotificationService::class.java)
    
    private val notificationsCreatedCounter: Counter = Counter.builder("notifications_created_total")
        .description("Total number of notifications created")
        .register(meterRegistry)
    
    private val notificationsReadCounter: Counter = Counter.builder("notifications_read_total")
        .description("Total number of notifications marked as read")
        .register(meterRegistry)
    
    init {
        Gauge.builder("notifications_unread_gauge", notificationRepository) { repo ->
            repo.countByUserIdAndReadAtIsNull(0).toDouble()
        }
            .description("Number of unread notifications")
            .register(meterRegistry)
    }
    
    @Transactional
    fun createNotification(event: KafkaEvent): Notification {
        val message = generateMessage(event)
        
        val notification = Notification(
            userId = event.userId,
            eventType = event.eventType,
            message = message,
            metadata = event.metadata
        )
        
        val saved = notificationRepository.save(notification)
        notificationsCreatedCounter.increment()
        
        logger.info("[NOTIFICATION-SERVICE] [INFO] Notification created: ID=${saved.id}, User=${saved.userId}, Type=${saved.eventType}")
        
        return saved
    }
    
    fun getNotifications(userId: Long, unreadOnly: Boolean, page: Int, size: Int): NotificationPageResponse {
        val pageable = PageRequest.of(page, size)
        
        val notificationsPage = if (unreadOnly) {
            notificationRepository.findByUserIdAndReadAtIsNull(userId, pageable)
        } else {
            notificationRepository.findByUserId(userId, pageable)
        }
        
        return NotificationPageResponse(
            content = notificationsPage.content.map { NotificationResponse.from(it) },
            page = notificationsPage.number,
            size = notificationsPage.size,
            totalElements = notificationsPage.totalElements,
            totalPages = notificationsPage.totalPages
        )
    }
    
    fun getNotificationById(id: Long, userId: Long): NotificationResponse {
        val notification = notificationRepository.findById(id)
            .orElseThrow { NotificationNotFoundException("Notification with id $id not found") }
        
        if (notification.userId != userId) {
            throw NotificationNotFoundException("Notification with id $id not found")
        }
        
        return NotificationResponse.from(notification)
    }
    
    @Transactional
    fun markAsRead(id: Long, userId: Long): NotificationResponse {
        val notification = notificationRepository.findById(id)
            .orElseThrow { NotificationNotFoundException("Notification with id $id not found") }
        
        if (notification.userId != userId) {
            throw NotificationNotFoundException("Notification with id $id not found")
        }
        
        if (notification.readAt == null) {
            notification.readAt = Instant.now()
            notificationRepository.save(notification)
            notificationsReadCounter.increment()
        }
        
        return NotificationResponse.from(notification)
    }
    
    @Transactional
    fun markAllAsRead(userId: Long): MarkAllReadResponse {
        val count = notificationRepository.markAllAsReadByUserId(userId)
        notificationsReadCounter.increment(count.toDouble())
        
        return MarkAllReadResponse(
            message = "All notifications marked as read",
            count = count
        )
    }
    
    fun getUnreadCount(userId: Long): UnreadCountResponse {
        val count = notificationRepository.countByUserIdAndReadAtIsNull(userId)
        return UnreadCountResponse(userId = userId, unreadCount = count)
    }
    
    @Transactional
    fun deleteNotification(id: Long, userId: Long) {
        if (!notificationRepository.existsByIdAndUserId(id, userId)) {
            throw NotificationNotFoundException("Notification with id $id not found")
        }
        notificationRepository.deleteById(id)
    }
    
    private fun generateMessage(event: KafkaEvent): String {
        return when (event.eventType) {
            "USER_REGISTERED" -> "Welcome! Your account has been created successfully."
            "USER_LOGGED_IN" -> "You logged in to your account."
            "TASK_CREATED" -> "New task created: ${event.metadata["title"]}"
            "TASK_UPDATED" -> {
                val title = event.metadata["title"]
                val newStatus = event.metadata["newStatus"]
                "Task updated: $title - Status: $newStatus"
            }
            "TASK_COMPLETED" -> "Task completed: ${event.metadata["title"]} ✓"
            "TASK_DELETED" -> "Task deleted: ${event.metadata["title"]}"
            else -> "New notification"
        }
    }
}

