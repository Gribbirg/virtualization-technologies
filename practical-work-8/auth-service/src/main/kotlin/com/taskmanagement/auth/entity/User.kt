package com.taskmanagement.auth.entity

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "users", indexes = [
    Index(name = "idx_users_username", columnList = "username"),
    Index(name = "idx_users_email", columnList = "email")
])
data class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,
    
    @Column(unique = true, nullable = false, length = 50)
    val username: String,
    
    @Column(unique = true, nullable = false, length = 100)
    val email: String,
    
    @Column(name = "password_hash", nullable = false)
    val passwordHash: String,
    
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
)

