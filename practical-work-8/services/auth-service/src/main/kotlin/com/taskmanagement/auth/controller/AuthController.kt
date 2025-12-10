package com.taskmanagement.auth.controller

import com.taskmanagement.auth.dto.*
import com.taskmanagement.auth.service.AuthService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.servlet.http.HttpServletRequest
import jakarta.validation.Valid
import org.slf4j.LoggerFactory
import org.slf4j.MDC
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "User authentication and authorization endpoints")
class AuthController(
    private val authService: AuthService
) {
    private val logger = LoggerFactory.getLogger(AuthController::class.java)
    
    @PostMapping("/register")
    @Operation(summary = "Register a new user")
    fun register(
        @Valid @RequestBody request: RegisterRequest,
        httpRequest: HttpServletRequest
    ): ResponseEntity<UserResponse> {
        logRequest(httpRequest, "POST", "/api/auth/register")
        val response = authService.registerUser(request)
        logger.info("User registered: ${response.username}")
        return ResponseEntity.status(HttpStatus.CREATED).body(response)
    }
    
    @PostMapping("/login")
    @Operation(summary = "Login and receive JWT token")
    fun login(
        @Valid @RequestBody request: LoginRequest,
        httpRequest: HttpServletRequest
    ): ResponseEntity<LoginResponse> {
        logRequest(httpRequest, "POST", "/api/auth/login")
        val response = authService.login(request)
        logger.info("User logged in: ${response.username}")
        return ResponseEntity.ok(response)
    }
    
    @GetMapping("/validate")
    @Operation(summary = "Validate JWT token")
    fun validate(
        @RequestHeader("Authorization") authorization: String,
        httpRequest: HttpServletRequest
    ): ResponseEntity<TokenValidationResponse> {
        logRequest(httpRequest, "GET", "/api/auth/validate")
        val token = extractToken(authorization)
        val response = authService.validateToken(token)
        return if (response.valid) {
            ResponseEntity.ok(response)
        } else {
            ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response)
        }
    }
    
    @PostMapping("/logout")
    @Operation(summary = "Logout and invalidate token")
    fun logout(
        @RequestHeader("Authorization") authorization: String,
        httpRequest: HttpServletRequest
    ): ResponseEntity<LogoutResponse> {
        logRequest(httpRequest, "POST", "/api/auth/logout")
        val token = extractToken(authorization)
        authService.logout(token)
        logger.info("User logged out")
        return ResponseEntity.ok(LogoutResponse("Logged out successfully"))
    }
    
    @GetMapping("/me")
    @Operation(summary = "Get current user information")
    fun getCurrentUser(
        @RequestHeader("Authorization") authorization: String,
        httpRequest: HttpServletRequest
    ): ResponseEntity<UserResponse> {
        logRequest(httpRequest, "GET", "/api/auth/me")
        val token = extractToken(authorization)
        val response = authService.getCurrentUser(token)
        return ResponseEntity.ok(response)
    }
    
    private fun extractToken(authorization: String): String {
        if (!authorization.startsWith("Bearer ")) {
            throw IllegalArgumentException("Invalid Authorization header format")
        }
        return authorization.substring(7)
    }
    
    private fun logRequest(request: HttpServletRequest, method: String, url: String) {
        val ipAddress = request.remoteAddr
        MDC.put("http_method", method)
        MDC.put("url", url)
        MDC.put("ip_address", ipAddress)
        logger.info("$method $url from $ipAddress")
    }
}

