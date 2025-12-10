package com.taskmanagement.auth.dto

import java.time.LocalDateTime

data class AuthEvent(
    val eventType: String,
    val userId: Long,
    val username: String,
    val email: String? = null,
    val timestamp: LocalDateTime = LocalDateTime.now()
)

