package com.taskmanagement.notification.service

import com.taskmanagement.notification.dto.UserInfo
import com.taskmanagement.notification.exception.UnauthorizedException
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.HttpEntity
import org.springframework.http.HttpHeaders
import org.springframework.http.HttpMethod
import org.springframework.stereotype.Service
import org.springframework.web.client.RestTemplate

@Service
class AuthClientService(
    @Value("\${auth-service.url}") private val authServiceUrl: String,
    private val restTemplate: RestTemplate = RestTemplate()
) {
    
    private val logger = LoggerFactory.getLogger(AuthClientService::class.java)
    
    fun validateToken(token: String): UserInfo {
        try {
            val headers = HttpHeaders().apply {
                set("Authorization", "Bearer $token")
            }
            
            val response = restTemplate.exchange(
                "$authServiceUrl/api/auth/validate",
                HttpMethod.GET,
                HttpEntity<Any>(headers),
                ValidationResponse::class.java
            )
            
            if (response.statusCode.is2xxSuccessful && response.body != null) {
                val body = response.body!!
                logger.debug("Token validated for user: ${body.userId}")
                return UserInfo(userId = body.userId, username = body.username)
            }
            
            throw UnauthorizedException("Invalid token")
        } catch (ex: Exception) {
            logger.error("Failed to validate token", ex)
            throw UnauthorizedException("Token validation failed")
        }
    }
    
    data class ValidationResponse(
        val userId: Long,
        val username: String
    )
}

