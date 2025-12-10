package com.taskmanagement.notification.dto

import com.taskmanagement.notification.entity.Notification
import java.time.Instant

data class NotificationResponse(
    val id: Long,
    val userId: Long,
    val eventType: String,
    val message: String,
    val metadata: Map<String, Any>?,
    val createdAt: Instant,
    val readAt: Instant?
) {
    companion object {
        fun from(notification: Notification): NotificationResponse {
            return NotificationResponse(
                id = notification.id!!,
                userId = notification.userId,
                eventType = notification.eventType,
                message = notification.message,
                metadata = notification.metadata,
                createdAt = notification.createdAt,
                readAt = notification.readAt
            )
        }
    }
}

