package com.example.demo.dtos.UserProfile;

import java.util.Set;

import com.example.demo.entities.UserStatus;

public record UserProfileRequest(
    String firstName,
    String lastName,
    String description,
    UserStatus status,
    Set<String> skills,
    Set<String> interests
) {}
