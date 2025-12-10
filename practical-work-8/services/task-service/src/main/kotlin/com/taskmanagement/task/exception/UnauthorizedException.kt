package com.taskmanagement.task.exception

class UnauthorizedException(message: String = "Unauthorized - invalid or missing token") : RuntimeException(message)

