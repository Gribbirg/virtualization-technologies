package com.taskmanagement.notification.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.client.RestTemplate

@Configuration
class AuthClientConfig {
    
    @Bean
    fun restTemplate(): RestTemplate {
        return RestTemplate()
    }
}

