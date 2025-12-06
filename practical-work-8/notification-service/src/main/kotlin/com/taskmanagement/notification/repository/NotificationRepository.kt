package com.taskmanagement.notification.repository

import com.taskmanagement.notification.entity.Notification
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface NotificationRepository : JpaRepository<Notification, Long> {
    
    fun findByUserId(userId: Long, pageable: Pageable): Page<Notification>
    
    fun findByUserIdAndReadAtIsNull(userId: Long, pageable: Pageable): Page<Notification>
    
    fun countByUserIdAndReadAtIsNull(userId: Long): Long
    
    @Modifying
    @Query("UPDATE Notification n SET n.readAt = CURRENT_TIMESTAMP WHERE n.userId = :userId AND n.readAt IS NULL")
    fun markAllAsReadByUserId(userId: Long): Int
    
    fun existsByIdAndUserId(id: Long, userId: Long): Boolean
}

