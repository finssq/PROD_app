package com.example.demo.dtos.UserProfile;

import java.util.Set;
import java.util.UUID;

import com.example.demo.entities.UserProfile;
import com.example.demo.entities.UserStatus;

public record UserProfileResponse(
        UUID id,
        String firstName,
        String lastName,
        String description,
        UserStatus status,
        Set<String> skills,
        Set<String> interests,
        Integer starCount,              
        Boolean starredByCurrentUser    
) {

    public static UserProfileResponse from(UserProfile user, UUID currentUserId) {
        boolean starredByMe = user.getStars().stream()
                .anyMatch(u -> u.getId().equals(currentUserId));

        return new UserProfileResponse(
                user.getId(),
                user.getFirstName(),
                user.getLastName(),
                user.getDescription(),
                user.getStatus(),
                user.getSkills(),
                user.getInterests(),
                user.getStars().size(),
                starredByMe
        );
    }
}
