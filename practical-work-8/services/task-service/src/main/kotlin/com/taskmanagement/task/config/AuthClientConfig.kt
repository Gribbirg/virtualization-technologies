package com.taskmanagement.task.config

import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.client.RestTemplate

@Configuration
class AuthClientConfig {

    @Value("\${auth-service.url}")
    lateinit var authServiceUrl: String

    @Bean
    fun restTemplate(): RestTemplate {
        return RestTemplate()
    }
}

