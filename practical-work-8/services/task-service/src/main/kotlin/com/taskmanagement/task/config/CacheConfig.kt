package com.taskmanagement.task.config

import com.github.benmanes.caffeine.cache.Caffeine
import org.springframework.beans.factory.annotation.Value
import org.springframework.cache.CacheManager
import org.springframework.cache.caffeine.CaffeineCacheManager
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import java.util.concurrent.TimeUnit

@Configuration
class CacheConfig {

    @Value("\${auth-service.validation-cache-ttl:300}")
    private var cacheTtl: Long = 300

    @Bean
    fun cacheManager(): CacheManager {
        val cacheManager = CaffeineCacheManager("tokenValidation")
        cacheManager.setCaffeine(
            Caffeine.newBuilder()
                .expireAfterWrite(cacheTtl, TimeUnit.SECONDS)
                .maximumSize(1000)
        )
        return cacheManager
    }
}

