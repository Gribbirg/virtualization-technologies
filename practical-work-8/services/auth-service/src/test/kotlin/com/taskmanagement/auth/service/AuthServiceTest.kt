package com.taskmanagement.auth.service

import com.taskmanagement.auth.dto.LoginRequest
import com.taskmanagement.auth.dto.RegisterRequest
import com.taskmanagement.auth.entity.User
import com.taskmanagement.auth.exception.InvalidCredentialsException
import com.taskmanagement.auth.exception.UserAlreadyExistsException
import com.taskmanagement.auth.repository.UserRepository
import io.micrometer.core.instrument.Counter
import io.micrometer.core.instrument.MeterRegistry
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.security.crypto.password.PasswordEncoder
import java.time.LocalDateTime
import java.util.*

class AuthServiceTest {
    
    private lateinit var userRepository: UserRepository
    private lateinit var passwordEncoder: PasswordEncoder
    private lateinit var tokenService: TokenService
    private lateinit var kafkaProducerService: KafkaProducerService
    private lateinit var meterRegistry: MeterRegistry
    private lateinit var authService: AuthService
    
    @BeforeEach
    fun setup() {
        userRepository = mockk()
        passwordEncoder = mockk()
        tokenService = mockk()
        kafkaProducerService = mockk(relaxed = true)
        meterRegistry = mockk(relaxed = true)
        
        authService = AuthService(
            userRepository,
            passwordEncoder,
            tokenService,
            kafkaProducerService,
            meterRegistry
        )
    }
    
    @Test
    fun `registerUser should create new user successfully`() {
        val request = RegisterRequest("testuser", "test@example.com", "password123")
        val hashedPassword = "hashed_password"
        val savedUser = User(
            id = 1L,
            username = request.username,
            email = request.email,
            passwordHash = hashedPassword,
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
        
        every { userRepository.existsByUsername(request.username) } returns false
        every { userRepository.existsByEmail(request.email) } returns false
        every { passwordEncoder.encode(request.password) } returns hashedPassword
        every { userRepository.save(any()) } returns savedUser
        
        val response = authService.registerUser(request)
        
        assertEquals(1L, response.id)
        assertEquals(request.username, response.username)
        assertEquals(request.email, response.email)
        
        verify { userRepository.save(any()) }
        verify { kafkaProducerService.publishEvent(any()) }
    }
    
    @Test
    fun `registerUser should throw exception when username exists`() {
        val request = RegisterRequest("testuser", "test@example.com", "password123")
        
        every { userRepository.existsByUsername(request.username) } returns true
        
        assertThrows(UserAlreadyExistsException::class.java) {
            authService.registerUser(request)
        }
    }
    
    @Test
    fun `registerUser should throw exception when email exists`() {
        val request = RegisterRequest("testuser", "test@example.com", "password123")
        
        every { userRepository.existsByUsername(request.username) } returns false
        every { userRepository.existsByEmail(request.email) } returns true
        
        assertThrows(UserAlreadyExistsException::class.java) {
            authService.registerUser(request)
        }
    }
    
    @Test
    fun `login should return token for valid credentials`() {
        val request = LoginRequest("testuser", "password123")
        val user = User(
            id = 1L,
            username = request.username,
            email = "test@example.com",
            passwordHash = "hashed_password",
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
        val token = "jwt.token.here"
        
        every { userRepository.findByUsername(request.username) } returns user
        every { passwordEncoder.matches(request.password, user.passwordHash) } returns true
        every { tokenService.generateToken(user.id!!, user.username) } returns token
        
        val response = authService.login(request)
        
        assertEquals(token, response.token)
        assertEquals(user.id, response.userId)
        assertEquals(user.username, response.username)
        
        verify { tokenService.generateToken(user.id!!, user.username) }
        verify { kafkaProducerService.publishEvent(any()) }
    }
    
    @Test
    fun `login should throw exception when user not found`() {
        val request = LoginRequest("testuser", "password123")
        
        every { userRepository.findByUsername(request.username) } returns null
        
        assertThrows(InvalidCredentialsException::class.java) {
            authService.login(request)
        }
    }
    
    @Test
    fun `login should throw exception when password is invalid`() {
        val request = LoginRequest("testuser", "password123")
        val user = User(
            id = 1L,
            username = request.username,
            email = "test@example.com",
            passwordHash = "hashed_password",
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
        
        every { userRepository.findByUsername(request.username) } returns user
        every { passwordEncoder.matches(request.password, user.passwordHash) } returns false
        
        assertThrows(InvalidCredentialsException::class.java) {
            authService.login(request)
        }
    }
    
    @Test
    fun `validateToken should return valid response for valid token`() {
        val token = "valid.token"
        val userId = 1L
        val username = "testuser"
        
        every { tokenService.validateToken(token) } returns Pair(userId, username)
        
        val response = authService.validateToken(token)
        
        assertTrue(response.valid)
        assertEquals(userId, response.userId)
        assertEquals(username, response.username)
        assertNull(response.error)
    }
    
    @Test
    fun `logout should invalidate token`() {
        val token = "valid.token"
        val userId = 1L
        val username = "testuser"
        
        every { tokenService.validateToken(token) } returns Pair(userId, username)
        every { tokenService.invalidateToken(token) } returns Unit
        
        authService.logout(token)
        
        verify { tokenService.invalidateToken(token) }
        verify { kafkaProducerService.publishEvent(any()) }
    }
    
    @Test
    fun `getCurrentUser should return user info`() {
        val token = "valid.token"
        val userId = 1L
        val user = User(
            id = userId,
            username = "testuser",
            email = "test@example.com",
            passwordHash = "hashed_password",
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
        
        every { tokenService.validateToken(token) } returns Pair(userId, user.username)
        every { userRepository.findById(userId) } returns Optional.of(user)
        
        val response = authService.getCurrentUser(token)
        
        assertEquals(userId, response.id)
        assertEquals(user.username, response.username)
        assertEquals(user.email, response.email)
    }
}

