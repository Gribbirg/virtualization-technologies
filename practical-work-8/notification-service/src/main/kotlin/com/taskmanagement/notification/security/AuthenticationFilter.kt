package com.taskmanagement.notification.security

import com.taskmanagement.notification.dto.UserInfo
import com.taskmanagement.notification.service.AuthClientService
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

@Component
class AuthenticationFilter(
    private val authClientService: AuthClientService
) : OncePerRequestFilter() {
    
    private val logger = LoggerFactory.getLogger(AuthenticationFilter::class.java)
    
    companion object {
        const val USER_INFO_ATTRIBUTE = "userInfo"
    }
    
    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain
    ) {
        val path = request.requestURI
        
        if (path.startsWith("/actuator") || path.startsWith("/v3/api-docs") || path.startsWith("/swagger-ui")) {
            filterChain.doFilter(request, response)
            return
        }
        
        val authHeader = request.getHeader("Authorization")
        
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            response.status = HttpServletResponse.SC_UNAUTHORIZED
            response.writer.write("{\"error\":\"UNAUTHORIZED\",\"message\":\"Missing or invalid Authorization header\"}")
            return
        }
        
        try {
            val token = authHeader.substring(7)
            val userInfo = authClientService.validateToken(token)
            request.setAttribute(USER_INFO_ATTRIBUTE, userInfo)
            
            filterChain.doFilter(request, response)
        } catch (ex: Exception) {
            logger.error("Authentication failed", ex)
            response.status = HttpServletResponse.SC_UNAUTHORIZED
            response.writer.write("{\"error\":\"UNAUTHORIZED\",\"message\":\"Invalid token\"}")
        }
    }
}

