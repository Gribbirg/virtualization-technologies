package com.taskmanagement.task.dto

data class TaskStatsResponse(
    val userId: Long,
    val totalTasks: Long,
    val pendingTasks: Long,
    val inProgressTasks: Long,
    val completedTasks: Long,
    val cancelledTasks: Long
)

