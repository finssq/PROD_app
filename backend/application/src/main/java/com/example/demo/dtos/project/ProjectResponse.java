package com.example.demo.dtos.project;

import java.util.Set;

import com.example.demo.dtos.UserProfile.UserProfileResponse;
import com.example.demo.entities.ProjectStatus;

public record ProjectResponse(
    Long id,
    UserProfileResponse organizer,
    String name,
    String description,
    Set<String> tags,
    Set<UserProfileResponse> participants,
    Integer likeCount,         
    Boolean likedByCurrentUser,
    String invitationCode,
    ProjectStatus status
) {}
