package com.example.demo.controllers;

import java.util.List;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dtos.UserProfile.UserProfileRequest;
import com.example.demo.dtos.UserProfile.UserProfileResponse;
import com.example.demo.dtos.UserProfile.UserProfileSearchRequest;
import com.example.demo.services.UserProfileService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/user-profiles")
@RequiredArgsConstructor
@Tag(name = "UserProfile", description = "API для работы с профилями пользователей")
public class UserProfileController {

    private final UserProfileService userProfileService;

    @Operation(summary = "Создать профиль пользователя", description = "Создаёт новый профиль пользователя с навыками и интересами")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Профиль успешно создан", 
                    content = @Content(schema = @Schema(implementation = UserProfileResponse.class))),
            @ApiResponse(responseCode = "400", description = "Некорректные данные запроса")
    })
    @PostMapping
    public ResponseEntity<UserProfileResponse> create(
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "Данные для создания профиля пользователя",
                    required = true,
                    content = @Content(schema = @Schema(implementation = UserProfileRequest.class))
            )
            @RequestBody UserProfileRequest request) {
        UserProfileResponse response = userProfileService.create(request);
        return ResponseEntity.status(201).body(response); 
    }

    @GetMapping("/recommendations")
    public ResponseEntity<List<UserProfileResponse>> getRecommendations() {
        return ResponseEntity.ok(userProfileService.getRecommendations());
    }

    @GetMapping
    public ResponseEntity<List<UserProfileResponse>> findAll() {
        List<UserProfileResponse> profiles = userProfileService.findAll();
        return ResponseEntity.ok(profiles);
    }

    @PostMapping("/search")
    @Operation(summary = "Поиск профилей пользователей", description = "Ищет профили по имени, фамилии, статусу, навыкам и интересам")
    public ResponseEntity<List<UserProfileResponse>> search(@RequestBody UserProfileSearchRequest request) {
        List<UserProfileResponse> results = userProfileService.search(request);
        return ResponseEntity.ok(results);
    }

    @Operation(summary = "Получить профиль пользователя по ID", description = "Возвращает профиль пользователя по его уникальному идентификатору")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Профиль найден", 
                    content = @Content(schema = @Schema(implementation = UserProfileResponse.class))),
            @ApiResponse(responseCode = "404", description = "Профиль не найден")
    })
    @GetMapping("/{id}")
    public ResponseEntity<UserProfileResponse> getById(
            @Parameter(description = "ID пользователя", required = true)
            @PathVariable UUID id) {
        UserProfileResponse response = userProfileService.getById(id);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Обновить профиль пользователя", description = "Обновляет существующий профиль пользователя по ID")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Профиль успешно обновлён", 
                    content = @Content(schema = @Schema(implementation = UserProfileResponse.class))),
            @ApiResponse(responseCode = "404", description = "Профиль не найден"),
            @ApiResponse(responseCode = "400", description = "Некорректные данные запроса")
    })
    @PutMapping("/{id}")
    public ResponseEntity<UserProfileResponse> update(
            @Parameter(description = "ID пользователя", required = true)
            @PathVariable UUID id,
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "Данные для обновления профиля пользователя",
                    required = true,
                    content = @Content(schema = @Schema(implementation = UserProfileRequest.class))
            )
            @RequestBody UserProfileRequest request) {
        UserProfileResponse response = userProfileService.update(id, request);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Удалить профиль пользователя", description = "Удаляет профиль пользователя по ID")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Профиль успешно удалён"),
            @ApiResponse(responseCode = "404", description = "Профиль не найден")
    })
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @Parameter(description = "ID пользователя", required = true)
            @PathVariable UUID id) {
        userProfileService.delete(id);
        return ResponseEntity.noContent().build(); 
    }
}