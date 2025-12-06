package com.taskmanagement.task.dto

data class TaskPageResponse(
    val content: List<TaskResponse>,
    val page: Int,
    val size: Int,
    val totalElements: Long,
    val totalPages: Int
)

