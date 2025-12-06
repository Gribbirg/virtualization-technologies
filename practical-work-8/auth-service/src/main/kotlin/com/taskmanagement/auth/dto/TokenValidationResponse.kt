package com.taskmanagement.auth.dto

data class TokenValidationResponse(
    val valid: Boolean,
    val userId: Long? = null,
    val username: String? = null,
    val error: String? = null
)

