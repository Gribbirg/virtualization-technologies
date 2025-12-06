package com.taskmanagement.task.entity

import jakarta.persistence.*
import java.time.Instant

@Entity
@Table(
    name = "tasks",
    indexes = [
        Index(name = "idx_tasks_user_id", columnList = "user_id"),
        Index(name = "idx_tasks_status", columnList = "status"),
        Index(name = "idx_tasks_created_at", columnList = "created_at")
    ]
)
data class Task(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @Column(name = "user_id", nullable = false)
    val userId: Long,

    @Column(nullable = false, length = 200)
    var title: String,

    @Column(columnDefinition = "TEXT")
    var description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    var status: TaskStatus = TaskStatus.PENDING,

    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: Instant = Instant.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: Instant = Instant.now()
)

