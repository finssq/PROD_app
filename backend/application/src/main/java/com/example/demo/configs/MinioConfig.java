package com.example.demo.configs;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.minio.MinioClient;

@Configuration
public class MinioConfig {

    @Value("${minio.endpoint}")
    private String ENDPOINT; 
    private static final String ACCESS_KEY = "minioaccesskey"; 
    private static final String SECRET_KEY = "miniosecretkey"; 

    @Bean
    public MinioClient minioClient() {
        return MinioClient.builder()
            .endpoint(ENDPOINT)
            .credentials(ACCESS_KEY, SECRET_KEY)
            .build();
    }
}
