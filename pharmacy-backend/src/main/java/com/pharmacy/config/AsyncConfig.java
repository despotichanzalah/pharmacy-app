package com.pharmacy.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;

// Enables @Async so email sending never blocks a login or registration response.
@Configuration
@EnableAsync
public class AsyncConfig {
}
