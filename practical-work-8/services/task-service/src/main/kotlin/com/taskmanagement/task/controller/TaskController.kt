package com.taskmanagement.task.controller

import com.taskmanagement.task.dto.*
import com.taskmanagement.task.entity.TaskStatus
import com.taskmanagement.task.service.TaskService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.servlet.http.HttpServletRequest
import jakarta.validation.Valid
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/tasks")
@Tag(name = "Task Management", description = "Task CRUD operations")
class TaskController(
    private val taskService: TaskService
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    @PostMapping
    @Operation(summary = "Create a new task")
    fun createTask(
        @Valid @RequestBody request: CreateTaskRequest,
        httpRequest: HttpServletRequest
    ): ResponseEntity<TaskResponse> {
        val userId = httpRequest.getAttribute("userId") as Long
        logger.info("POST /api/tasks - User: $userId - Creating task: '${request.title}'")
        
        val response = taskService.createTask(request, userId)
        return ResponseEntity.status(HttpStatus.CREATED).body(response)
    }

    @GetMapping
    @Operation(summary = "Get all tasks for current user")
    fun getTasks(
        @Parameter(description = "Filter by status") @RequestParam(required = false) status: TaskStatus?,
        @Parameter(description = "Page number") @RequestParam(defaultValue = "0") page: Int,
        @Parameter(description = "Page size") @RequestParam(defaultValue = "20") size: Int,
        httpRequest: HttpServletRequest
    ): ResponseEntity<TaskPageResponse> {
        val userId = httpRequest.getAttribute("userId") as Long
        logger.info("GET /api/tasks - User: $userId - Fetching tasks (status=$status, page=$page, size=$size)")
        
        val response = taskService.getTasks(userId, status, page, size)
        return ResponseEntity.ok(response)
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get task by ID")
    fun getTaskById(
        @PathVariable id: Long,
        httpRequest: HttpServletRequest
    ): ResponseEntity<TaskResponse> {
        val userId = httpRequest.getAttribute("userId") as Long
        logger.info("GET /api/tasks/$id - User: $userId")
        
        val response = taskService.getTaskById(id, userId)
        return ResponseEntity.ok(response)
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update task")
    fun updateTask(
        @PathVariable id: Long,
        @Valid @RequestBody request: UpdateTaskRequest,
        httpRequest: HttpServletRequest
    ): ResponseEntity<TaskResponse> {
        val userId = httpRequest.getAttribute("userId") as Long
        logger.info("PUT /api/tasks/$id - User: $userId - Updating task")
        
        val response = taskService.updateTask(id, request, userId)
        return ResponseEntity.ok(response)
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete task")
    fun deleteTask(
        @PathVariable id: Long,
        httpRequest: HttpServletRequest
    ): ResponseEntity<Void> {
        val userId = httpRequest.getAttribute("userId") as Long
        logger.info("DELETE /api/tasks/$id - User: $userId")
        
        taskService.deleteTask(id, userId)
        return ResponseEntity.noContent().build()
    }

    @GetMapping("/stats")
    @Operation(summary = "Get task statistics for current user")
    fun getStats(
        httpRequest: HttpServletRequest
    ): ResponseEntity<TaskStatsResponse> {
        val userId = httpRequest.getAttribute("userId") as Long
        logger.info("GET /api/tasks/stats - User: $userId")
        
        val response = taskService.getTaskStats(userId)
        return ResponseEntity.ok(response)
    }
}

