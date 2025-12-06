package com.taskmanagement.notification.controller

import com.taskmanagement.notification.dto.MarkAllReadResponse
import com.taskmanagement.notification.dto.NotificationPageResponse
import com.taskmanagement.notification.dto.NotificationResponse
import com.taskmanagement.notification.dto.UnreadCountResponse
import com.taskmanagement.notification.dto.UserInfo
import com.taskmanagement.notification.security.AuthenticationFilter
import com.taskmanagement.notification.service.NotificationService
import jakarta.servlet.http.HttpServletRequest
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/notifications")
class NotificationController(
    private val notificationService: NotificationService
) {
    
    private val logger = LoggerFactory.getLogger(NotificationController::class.java)
    
    @GetMapping
    fun getNotifications(
        @RequestParam(defaultValue = "false") unreadOnly: Boolean,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int,
        request: HttpServletRequest
    ): NotificationPageResponse {
        val userInfo = request.getAttribute(AuthenticationFilter.USER_INFO_ATTRIBUTE) as UserInfo
        
        logger.info("[NOTIFICATION-SERVICE] [INFO] GET /api/notifications from ${request.remoteAddr} - Status: 200 - User: ${userInfo.userId}")
        
        return notificationService.getNotifications(userInfo.userId, unreadOnly, page, size)
    }
    
    @GetMapping("/{id}")
    fun getNotificationById(
        @PathVariable id: Long,
        request: HttpServletRequest
    ): NotificationResponse {
        val userInfo = request.getAttribute(AuthenticationFilter.USER_INFO_ATTRIBUTE) as UserInfo
        
        logger.info("[NOTIFICATION-SERVICE] [INFO] GET /api/notifications/$id from ${request.remoteAddr} - Status: 200 - User: ${userInfo.userId}")
        
        return notificationService.getNotificationById(id, userInfo.userId)
    }
    
    @PostMapping("/{id}/read")
    fun markAsRead(
        @PathVariable id: Long,
        request: HttpServletRequest
    ): NotificationResponse {
        val userInfo = request.getAttribute(AuthenticationFilter.USER_INFO_ATTRIBUTE) as UserInfo
        
        logger.info("[NOTIFICATION-SERVICE] [INFO] POST /api/notifications/$id/read from ${request.remoteAddr} - Status: 200 - User: ${userInfo.userId}")
        
        return notificationService.markAsRead(id, userInfo.userId)
    }
    
    @PostMapping("/read-all")
    fun markAllAsRead(request: HttpServletRequest): MarkAllReadResponse {
        val userInfo = request.getAttribute(AuthenticationFilter.USER_INFO_ATTRIBUTE) as UserInfo
        
        logger.info("[NOTIFICATION-SERVICE] [INFO] POST /api/notifications/read-all from ${request.remoteAddr} - Status: 200 - User: ${userInfo.userId}")
        
        return notificationService.markAllAsRead(userInfo.userId)
    }
    
    @GetMapping("/unread-count")
    fun getUnreadCount(request: HttpServletRequest): UnreadCountResponse {
        val userInfo = request.getAttribute(AuthenticationFilter.USER_INFO_ATTRIBUTE) as UserInfo
        
        logger.info("[NOTIFICATION-SERVICE] [INFO] GET /api/notifications/unread-count from ${request.remoteAddr} - Status: 200 - User: ${userInfo.userId}")
        
        return notificationService.getUnreadCount(userInfo.userId)
    }
    
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteNotification(
        @PathVariable id: Long,
        request: HttpServletRequest
    ) {
        val userInfo = request.getAttribute(AuthenticationFilter.USER_INFO_ATTRIBUTE) as UserInfo
        
        logger.info("[NOTIFICATION-SERVICE] [INFO] DELETE /api/notifications/$id from ${request.remoteAddr} - Status: 204 - User: ${userInfo.userId}")
        
        notificationService.deleteNotification(id, userInfo.userId)
    }
}

