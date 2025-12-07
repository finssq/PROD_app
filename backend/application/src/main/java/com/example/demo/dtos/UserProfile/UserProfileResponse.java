package com.example.demo.dtos.UserProfile;

import java.util.Set;
import java.util.UUID;

import com.example.demo.entities.UserStatus;

public record UserProfileResponse(
    UUID id,
    String firstName,
    String lastName,
    String description,
    UserStatus status,
    Set<String> skills,
    Set<String> interests
) {}