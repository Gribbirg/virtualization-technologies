package com.taskmanagement.task.exception

class AccessDeniedException(message: String = "Access denied - task belongs to another user") : RuntimeException(message)

