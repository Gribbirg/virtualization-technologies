package com.taskmanagement.notification.dto

import com.fasterxml.jackson.annotation.JsonIgnoreProperties

@JsonIgnoreProperties(ignoreUnknown = true)
data class KafkaEvent(
    val eventType: String = "",
    val userId: Long = 0,
    val username: String? = null,
    val email: String? = null,
    val timestamp: Any? = null,
    val title: String? = null,
    val description: String? = null,
    val status: String? = null,
    val metadata: Map<String, Any> = emptyMap()
)

