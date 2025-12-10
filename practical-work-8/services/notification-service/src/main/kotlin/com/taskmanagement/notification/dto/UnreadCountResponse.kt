package com.taskmanagement.notification.dto

data class UnreadCountResponse(
    val userId: Long,
    val unreadCount: Long
)

