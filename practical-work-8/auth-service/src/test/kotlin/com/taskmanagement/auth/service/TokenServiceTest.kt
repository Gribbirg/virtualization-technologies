package com.taskmanagement.auth.service

import com.taskmanagement.auth.exception.InvalidTokenException
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.data.redis.core.RedisTemplate
import org.springframework.data.redis.core.ValueOperations
import java.util.concurrent.TimeUnit

class TokenServiceTest {
    
    private lateinit var redisTemplate: RedisTemplate<String, String>
    private lateinit var valueOperations: ValueOperations<String, String>
    private lateinit var tokenService: TokenService
    
    private val jwtSecret = "test-secret-key-for-jwt-token-generation-must-be-long-enough"
    private val jwtExpiration = 86400000L
    
    @BeforeEach
    fun setup() {
        redisTemplate = mockk(relaxed = true)
        valueOperations = mockk(relaxed = true)
        
        every { redisTemplate.opsForValue() } returns valueOperations
        
        tokenService = TokenService(redisTemplate, jwtSecret, jwtExpiration)
    }
    
    @Test
    fun `generateToken should create valid JWT and store in Redis`() {
        val userId = 1L
        val username = "testuser"
        
        val token = tokenService.generateToken(userId, username)
        
        assertNotNull(token)
        assertTrue(token.isNotEmpty())
        
        verify {
            valueOperations.set(
                match { it.startsWith("auth:token:") },
                userId.toString(),
                jwtExpiration,
                TimeUnit.MILLISECONDS
            )
        }
    }
    
    @Test
    fun `validateToken should return user info for valid token`() {
        val userId = 1L
        val username = "testuser"
        
        val token = tokenService.generateToken(userId, username)
        
        every { redisTemplate.hasKey(any()) } returns true
        
        val (returnedUserId, returnedUsername) = tokenService.validateToken(token)
        
        assertEquals(userId, returnedUserId)
        assertEquals(username, returnedUsername)
    }
    
    @Test
    fun `validateToken should throw exception when token not in Redis`() {
        val userId = 1L
        val username = "testuser"
        
        val token = tokenService.generateToken(userId, username)
        
        every { redisTemplate.hasKey(any()) } returns false
        
        assertThrows(InvalidTokenException::class.java) {
            tokenService.validateToken(token)
        }
    }
    
    @Test
    fun `validateToken should throw exception for invalid token`() {
        val invalidToken = "invalid.token.here"
        
        assertThrows(InvalidTokenException::class.java) {
            tokenService.validateToken(invalidToken)
        }
    }
    
    @Test
    fun `invalidateToken should remove token from Redis`() {
        val token = "test-token"
        
        tokenService.invalidateToken(token)
        
        verify {
            redisTemplate.delete("auth:token:$token")
        }
    }
}

