package com.taskmanagement.task.service

import com.taskmanagement.task.config.AuthClientConfig
import com.taskmanagement.task.dto.UserInfo
import com.taskmanagement.task.exception.UnauthorizedException
import org.slf4j.LoggerFactory
import org.springframework.cache.annotation.Cacheable
import org.springframework.http.HttpEntity
import org.springframework.http.HttpHeaders
import org.springframework.http.HttpMethod
import org.springframework.stereotype.Service
import org.springframework.web.client.RestTemplate

@Service
class AuthClientService(
    private val restTemplate: RestTemplate,
    private val authClientConfig: AuthClientConfig
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    @Cacheable(value = ["tokenValidation"], key = "#token")
    fun validateToken(token: String): UserInfo {
        return try {
            val headers = HttpHeaders().apply {
                set("Authorization", "Bearer $token")
            }
            val entity = HttpEntity<Void>(headers)
            
            val url = "${authClientConfig.authServiceUrl}/api/auth/validate"
            val response = restTemplate.exchange(
                url,
                HttpMethod.GET,
                entity,
                UserInfo::class.java
            )
            
            val userInfo = response.body ?: throw UnauthorizedException("Invalid token response")
            
            if (!userInfo.valid) {
                throw UnauthorizedException("Token is not valid")
            }
            
            logger.debug("Token validated successfully for user: ${userInfo.userId}")
            userInfo
        } catch (e: Exception) {
            logger.error("Token validation failed: ${e.message}")
            throw UnauthorizedException("Token validation failed: ${e.message}")
        }
    }
}

