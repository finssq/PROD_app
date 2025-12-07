package com.example.demo.dtos.event;

import java.time.LocalDateTime;
import java.util.Set;

import com.example.demo.dtos.UserProfile.UserProfileResponse;

public record EventResponse(
    Long id,
    UserProfileResponse organizer,
    String name,
    String description,
    LocalDateTime  eventTime,
    String place,
    Set<String> tags,
    Set<UserProfileResponse> participantIds
) {}

