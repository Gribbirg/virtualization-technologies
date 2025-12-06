package com.taskmanagement.task.service

import com.taskmanagement.task.dto.*
import com.taskmanagement.task.entity.Task
import com.taskmanagement.task.entity.TaskStatus
import com.taskmanagement.task.exception.AccessDeniedException
import com.taskmanagement.task.exception.TaskNotFoundException
import com.taskmanagement.task.repository.TaskRepository
import io.micrometer.core.instrument.Counter
import io.micrometer.core.instrument.MeterRegistry
import org.slf4j.LoggerFactory
import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant

@Service
class TaskService(
    private val taskRepository: TaskRepository,
    private val kafkaProducerService: KafkaProducerService,
    private val meterRegistry: MeterRegistry
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    private val tasksCreatedCounter: Counter = Counter.builder("tasks_created_total")
        .description("Total number of tasks created")
        .register(meterRegistry)

    private val tasksUpdatedCounter: Counter = Counter.builder("tasks_updated_total")
        .description("Total number of tasks updated")
        .register(meterRegistry)

    private val tasksDeletedCounter: Counter = Counter.builder("tasks_deleted_total")
        .description("Total number of tasks deleted")
        .register(meterRegistry)

    @Transactional
    fun createTask(request: CreateTaskRequest, userId: Long): TaskResponse {
        val task = Task(
            userId = userId,
            title = request.title,
            description = request.description,
            status = request.status
        )

        val savedTask = taskRepository.save(task)
        tasksCreatedCounter.increment()

        kafkaProducerService.publishTaskCreated(
            taskId = savedTask.id!!,
            userId = userId,
            title = savedTask.title,
            status = savedTask.status.name
        )

        logger.info("Task created: id=${savedTask.id}, userId=$userId, title='${savedTask.title}'")
        return TaskResponse.from(savedTask)
    }

    fun getTasks(userId: Long, status: TaskStatus?, page: Int, size: Int): TaskPageResponse {
        val pageable = PageRequest.of(page, size)
        val taskPage = if (status != null) {
            taskRepository.findByUserIdAndStatus(userId, status, pageable)
        } else {
            taskRepository.findByUserId(userId, pageable)
        }

        val tasks = taskPage.content.map { TaskResponse.from(it) }
        
        return TaskPageResponse(
            content = tasks,
            page = taskPage.number,
            size = taskPage.size,
            totalElements = taskPage.totalElements,
            totalPages = taskPage.totalPages
        )
    }

    fun getTaskById(id: Long, userId: Long): TaskResponse {
        val task = taskRepository.findByIdAndUserId(id, userId)
            ?: throw TaskNotFoundException(id)

        return TaskResponse.from(task)
    }

    @Transactional
    fun updateTask(id: Long, request: UpdateTaskRequest, userId: Long): TaskResponse {
        val task = taskRepository.findByIdAndUserId(id, userId)
            ?: throw TaskNotFoundException(id)

        val oldStatus = task.status
        task.title = request.title
        task.description = request.description
        task.status = request.status
        task.updatedAt = Instant.now()

        val updatedTask = taskRepository.save(task)
        tasksUpdatedCounter.increment()

        kafkaProducerService.publishTaskUpdated(
            taskId = updatedTask.id!!,
            userId = userId,
            title = updatedTask.title,
            oldStatus = oldStatus.name,
            newStatus = updatedTask.status.name
        )

        if (updatedTask.status == TaskStatus.COMPLETED && oldStatus != TaskStatus.COMPLETED) {
            kafkaProducerService.publishTaskCompleted(
                taskId = id,
                userId = userId,
                title = updatedTask.title
            )
        }

        logger.info("Task updated: id=$id, userId=$userId, status: $oldStatus -> ${updatedTask.status}")
        return TaskResponse.from(updatedTask)
    }

    @Transactional
    fun deleteTask(id: Long, userId: Long) {
        val task = taskRepository.findByIdAndUserId(id, userId)
            ?: throw TaskNotFoundException(id)

        taskRepository.delete(task)
        tasksDeletedCounter.increment()

        kafkaProducerService.publishTaskDeleted(
            taskId = id,
            userId = userId
        )

        logger.info("Task deleted: id=$id, userId=$userId")
    }

    fun getTaskStats(userId: Long): TaskStatsResponse {
        val totalTasks = taskRepository.countByUserId(userId)
        val pendingTasks = taskRepository.countByUserIdAndStatus(userId, TaskStatus.PENDING)
        val inProgressTasks = taskRepository.countByUserIdAndStatus(userId, TaskStatus.IN_PROGRESS)
        val completedTasks = taskRepository.countByUserIdAndStatus(userId, TaskStatus.COMPLETED)
        val cancelledTasks = taskRepository.countByUserIdAndStatus(userId, TaskStatus.CANCELLED)

        return TaskStatsResponse(
            userId = userId,
            totalTasks = totalTasks,
            pendingTasks = pendingTasks,
            inProgressTasks = inProgressTasks,
            completedTasks = completedTasks,
            cancelledTasks = cancelledTasks
        )
    }
}

