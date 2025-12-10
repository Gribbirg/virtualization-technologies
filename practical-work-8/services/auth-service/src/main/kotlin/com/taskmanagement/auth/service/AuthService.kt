package com.taskmanagement.auth.service

import com.taskmanagement.auth.dto.*
import com.taskmanagement.auth.entity.User
import com.taskmanagement.auth.exception.InvalidCredentialsException
import com.taskmanagement.auth.exception.InvalidTokenException
import com.taskmanagement.auth.exception.UserAlreadyExistsException
import com.taskmanagement.auth.repository.UserRepository
import io.micrometer.core.instrument.Counter
import io.micrometer.core.instrument.MeterRegistry
import org.slf4j.LoggerFactory
import org.slf4j.MDC
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class AuthService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder,
    private val tokenService: TokenService,
    private val kafkaProducerService: KafkaProducerService,
    private val meterRegistry: MeterRegistry
) {
    private val logger = LoggerFactory.getLogger(AuthService::class.java)
    
    private val registrationCounter: Counter = Counter.builder("auth_registrations_total")
        .description("Total number of user registrations")
        .register(meterRegistry)
    
    private val loginCounter: Counter = Counter.builder("auth_logins_total")
        .description("Total number of successful logins")
        .register(meterRegistry)
    
    private val loginFailureCounter: Counter = Counter.builder("auth_login_failures_total")
        .description("Total number of failed login attempts")
        .register(meterRegistry)
    
    @Transactional
    fun registerUser(request: RegisterRequest): UserResponse {
        logger.info("Attempting to register user: ${request.username}")
        
        if (userRepository.existsByUsername(request.username)) {
            throw UserAlreadyExistsException("Username already exists: ${request.username}")
        }
        
        if (userRepository.existsByEmail(request.email)) {
            throw UserAlreadyExistsException("Email already exists: ${request.email}")
        }
        
        val passwordHash = passwordEncoder.encode(request.password)
        val user = User(
            username = request.username,
            email = request.email,
            passwordHash = passwordHash
        )
        
        val savedUser = userRepository.save(user)
        registrationCounter.increment()
        
        val userId = savedUser.id ?: throw IllegalStateException("User ID is null after save")
        
        logger.info("User registered successfully: ${savedUser.username} (ID: $userId)")
        
        kafkaProducerService.publishEvent(
            AuthEvent(
                eventType = "USER_REGISTERED",
                userId = userId,
                username = savedUser.username,
                email = savedUser.email
            )
        )
        
        return UserResponse(
            id = userId,
            username = savedUser.username,
            email = savedUser.email,
            createdAt = savedUser.createdAt
        )
    }
    
    @Transactional(readOnly = true)
    fun login(request: LoginRequest): LoginResponse {
        logger.info("Login attempt for user: ${request.username}")
        
        val user = userRepository.findByUsername(request.username)
            ?: run {
                loginFailureCounter.increment()
                logger.warn("Login failed: user not found - ${request.username}")
                throw InvalidCredentialsException()
            }
        
        if (!passwordEncoder.matches(request.password, user.passwordHash)) {
            loginFailureCounter.increment()
            logger.warn("Login failed: invalid password for user - ${request.username}")
            throw InvalidCredentialsException()
        }
        
        val userId = user.id ?: throw IllegalStateException("User ID is null")
        val token = tokenService.generateToken(userId, user.username)
        loginCounter.increment()
        
        logger.info("User logged in successfully: ${user.username} (ID: $userId)")
        MDC.put("user_id", userId.toString())
        
        kafkaProducerService.publishEvent(
            AuthEvent(
                eventType = "USER_LOGGED_IN",
                userId = userId,
                username = user.username
            )
        )
        
        return LoginResponse(
            token = token,
            userId = userId,
            username = user.username,
            expiresIn = 86400
        )
    }
    
    fun validateToken(token: String): TokenValidationResponse {
        return try {
            val (userId, username) = tokenService.validateToken(token)
            logger.debug("Token validation successful for user: $username")
            TokenValidationResponse(
                valid = true,
                userId = userId,
                username = username
            )
        } catch (ex: InvalidTokenException) {
            logger.warn("Token validation failed: ${ex.message}")
            TokenValidationResponse(
                valid = false,
                error = ex.message
            )
        }
    }
    
    fun logout(token: String) {
        try {
            val (userId, username) = tokenService.validateToken(token)
            tokenService.invalidateToken(token)
            
            logger.info("User logged out: $username (ID: $userId)")
            
            kafkaProducerService.publishEvent(
                AuthEvent(
                    eventType = "USER_LOGGED_OUT",
                    userId = userId,
                    username = username
                )
            )
        } catch (ex: InvalidTokenException) {
            logger.warn("Logout attempted with invalid token")
            throw ex
        }
    }
    
    @Transactional(readOnly = true)
    fun getCurrentUser(token: String): UserResponse {
        val (userId, _) = tokenService.validateToken(token)
        
        val user = userRepository.findById(userId).orElseThrow {
            logger.error("User not found: $userId")
            InvalidTokenException("User not found")
        }
        
        logger.debug("Retrieved current user: ${user.username}")
        
        return UserResponse(
            id = user.id ?: throw IllegalStateException("User ID is null"),
            username = user.username,
            email = user.email,
            createdAt = user.createdAt
        )
    }
}

