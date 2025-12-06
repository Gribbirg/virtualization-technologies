package com.taskmanagement.auth.dto

data class LoginResponse(
    val token: String,
    val userId: Long,
    val username: String,
    val expiresIn: Long = 86400
)

