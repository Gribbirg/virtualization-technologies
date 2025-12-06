package com.taskmanagement.auth.service

import com.taskmanagement.auth.exception.InvalidTokenException
import io.jsonwebtoken.Claims
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.data.redis.core.RedisTemplate
import org.springframework.stereotype.Service
import java.util.*
import java.util.concurrent.TimeUnit
import javax.crypto.SecretKey

@Service
class TokenService(
    private val redisTemplate: RedisTemplate<String, String>,
    @Value("\${jwt.secret}") private val jwtSecret: String,
    @Value("\${jwt.expiration}") private val jwtExpiration: Long
) {
    private val logger = LoggerFactory.getLogger(TokenService::class.java)
    private val secretKey: SecretKey = Keys.hmacShaKeyFor(jwtSecret.toByteArray())
    
    fun generateToken(userId: Long, username: String): String {
        val now = Date()
        val expiryDate = Date(now.time + jwtExpiration)
        
        val token = Jwts.builder()
            .subject(userId.toString())
            .claim("username", username)
            .issuedAt(now)
            .expiration(expiryDate)
            .signWith(secretKey)
            .compact()
        
        storeTokenInRedis(token, userId)
        logger.info("Generated token for user: $username (ID: $userId)")
        
        return token
    }
    
    fun validateToken(token: String): Pair<Long, String> {
        try {
            val claims = parseToken(token)
            val userId = claims.subject.toLong()
            val username = claims["username"] as String
            
            if (!isTokenInRedis(token)) {
                throw InvalidTokenException("Token not found or expired")
            }
            
            logger.debug("Token validated for user: $username (ID: $userId)")
            return Pair(userId, username)
        } catch (ex: Exception) {
            logger.warn("Token validation failed: ${ex.message}")
            throw InvalidTokenException("Invalid or expired token")
        }
    }
    
    fun invalidateToken(token: String) {
        val key = getRedisKey(token)
        redisTemplate.delete(key)
        logger.info("Token invalidated")
    }
    
    private fun parseToken(token: String): Claims {
        return Jwts.parser()
            .verifyWith(secretKey)
            .build()
            .parseSignedClaims(token)
            .payload
    }
    
    private fun storeTokenInRedis(token: String, userId: Long) {
        val key = getRedisKey(token)
        redisTemplate.opsForValue().set(key, userId.toString(), jwtExpiration, TimeUnit.MILLISECONDS)
    }
    
    private fun isTokenInRedis(token: String): Boolean {
        val key = getRedisKey(token)
        return redisTemplate.hasKey(key)
    }
    
    private fun getRedisKey(token: String): String = "auth:token:$token"
}

