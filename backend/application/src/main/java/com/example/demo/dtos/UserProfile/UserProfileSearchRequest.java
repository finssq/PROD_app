package com.example.demo.dtos.UserProfile;

import java.util.Set;

import com.example.demo.entities.UserStatus;

public record UserProfileSearchRequest(
    String text,
    Set<String> skills,
    Set<String> interests,
    UserStatus status
) {}

