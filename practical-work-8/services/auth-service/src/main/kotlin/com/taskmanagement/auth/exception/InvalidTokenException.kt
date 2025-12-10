package com.taskmanagement.auth.exception

class InvalidTokenException(message: String = "Invalid or expired token") : RuntimeException(message)

