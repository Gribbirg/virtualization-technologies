package com.taskmanagement.task.repository

import com.taskmanagement.task.entity.Task
import com.taskmanagement.task.entity.TaskStatus
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface TaskRepository : JpaRepository<Task, Long> {
    
    fun findByUserId(userId: Long, pageable: Pageable): Page<Task>
    
    fun findByUserIdAndStatus(userId: Long, status: TaskStatus, pageable: Pageable): Page<Task>
    
    fun countByUserId(userId: Long): Long
    
    fun countByUserIdAndStatus(userId: Long, status: TaskStatus): Long
    
    @Query("SELECT t FROM Task t WHERE t.id = :id AND t.userId = :userId")
    fun findByIdAndUserId(id: Long, userId: Long): Task?
}

