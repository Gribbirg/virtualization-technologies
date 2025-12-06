package com.taskmanagement.task.exception

class TaskNotFoundException(val taskId: Long) : RuntimeException("Task not found with id: $taskId")

