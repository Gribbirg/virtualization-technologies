package com.taskmanagement.task.dto

import com.taskmanagement.task.entity.TaskStatus
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class UpdateTaskRequest(
    @field:NotBlank(message = "Title is required")
    @field:Size(min = 1, max = 200, message = "Title must be between 1 and 200 characters")
    val title: String,

    @field:Size(max = 2000, message = "Description must not exceed 2000 characters")
    val description: String? = null,

    val status: TaskStatus
)

