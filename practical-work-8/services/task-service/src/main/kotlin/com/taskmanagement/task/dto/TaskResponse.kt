package com.taskmanagement.task.dto

import com.taskmanagement.task.entity.Task
import com.taskmanagement.task.entity.TaskStatus
import java.time.Instant

data class TaskResponse(
    val id: Long,
    val userId: Long,
    val title: String,
    val description: String?,
    val status: TaskStatus,
    val createdAt: Instant,
    val updatedAt: Instant
) {
    companion object {
        fun from(task: Task): TaskResponse {
            return TaskResponse(
                id = task.id!!,
                userId = task.userId,
                title = task.title,
                description = task.description,
                status = task.status,
                createdAt = task.createdAt,
                updatedAt = task.updatedAt
            )
        }
    }
}

