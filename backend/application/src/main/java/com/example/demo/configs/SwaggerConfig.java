package com.example.demo.configs;

import org.springdoc.core.properties.SwaggerUiOAuthProperties;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.security.OAuthFlow;
import io.swagger.v3.oas.models.security.OAuthFlows;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;

@Configuration
public class SwaggerConfig {

    @Value("${spring.security.oauth2.resourceserver.jwt.issuer-uri}")
    private String AUTH_SERVER_URL;

    @Value("${spring.security.oauth2.client.registration.keycloak.client-id}")
    private String CLIENT_ID;

    @Value("${spring.security.oauth2.client.registration.keycloak.client-secret}")
    private String CLIENT_SECRET;

    @Bean
    public OpenAPI customOpenAPI() {
        final String securitySchemeName = "oauth2_scheme"; 

        return new OpenAPI()
                .components(new Components()
                        .addSecuritySchemes("oauth2_scheme", createOAuthScheme()))
                .addSecurityItem(new SecurityRequirement().addList(securitySchemeName));
    }

    @Bean
    public SwaggerUiOAuthProperties swaggerUiOAuthProperties() {
        SwaggerUiOAuthProperties properties = new SwaggerUiOAuthProperties();

        properties.setClientId(CLIENT_ID);
        properties.setClientSecret(CLIENT_SECRET); 
        properties.setAppName("Monolith Spring Boot App");

        return properties;
    }

    private SecurityScheme createOAuthScheme() {
        OAuthFlows flows = new OAuthFlows()
                .authorizationCode(new OAuthFlow()
                        .authorizationUrl(AUTH_SERVER_URL + "/protocol/openid-connect/auth?prompt=login")
                        .tokenUrl(AUTH_SERVER_URL + "/protocol/openid-connect/token"));
        
        return new SecurityScheme()
                .type(SecurityScheme.Type.OAUTH2)
                .flows(flows);
    }
}
