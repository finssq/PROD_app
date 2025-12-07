package com.example.demo.controllers;

import org.springframework.web.bind.annotation.RestController;

import com.example.demo.security.IUserProfile;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;


@RestController
@RequestMapping("/api/security")
public class SecurityController {

    @Operation(summary = "Получить информацию о пользователе", 
                description = "Этот эндпоинт возвращает ID, fullName, email, authorities аутентифицированного пользователя, который сделал запрос.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Информация о пользователе успешно получена")
    })
    @GetMapping("/profile")
    public String userProfile(@AuthenticationPrincipal IUserProfile userProfile) {
        String email = userProfile.getEmail();
        String fullName = userProfile.getFullName();
        String id = userProfile.getUserId();
        List<GrantedAuthority> authorities = new ArrayList<>(userProfile.getAuthorities());

        String authoritiesStr = authorities.stream()
            .map(Object::toString)  
            .collect(Collectors.joining(", ")); 

        return String.format(
            "Hello, %s!<br>Your email is: %s<br>Your id: %s<br>Your authorities are: %s",
            fullName, email, id, authoritiesStr
        );
    }

    @Operation(summary = "Тестовый эндпоинт для пользователей с ролью USER", 
                description = "Этот эндпоинт доступен только для пользователей с ролью USER.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Пользователь аутентифицирован")
    })
    @GetMapping("/user")
    public String user() {
        return "Аутентифицирован";
    }

    @Operation(summary = "Тестовый эндпоинт для пользователей с ролью ADMIN", 
                description = "Этот эндпоинт доступен только для пользователей с ролью ADMIN.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Пользователь аутентифицирован")
    })
    @GetMapping("/admin")
    public String admin() {
        return "Аутентифицирован";
    }

    @Operation(summary = "Тестовый эндпоинт для пользователей с ролью ROOT", 
                description = "Этот эндпоинт доступен только для пользователей с ролью ROOT.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Пользователь аутентифицирован")
    })
    @GetMapping("/root")
    public String root() {
        return "Аутентифицирован";
    }
}
