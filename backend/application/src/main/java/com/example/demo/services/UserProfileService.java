package com.example.demo.services;

import java.util.List;
import java.util.Set;
import java.util.UUID;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.example.demo.dtos.UserProfile.UserProfileRequest;
import com.example.demo.dtos.UserProfile.UserProfileResponse;
import com.example.demo.dtos.UserProfile.UserProfileSearchRequest;
import com.example.demo.entities.UserProfile;
import com.example.demo.exception.exceptions.ResourceNotFoundException;
import com.example.demo.repositories.UserProfileRepository;
import com.example.demo.repositories.specifications.UserProfileSpecifications;
import com.example.demo.security.IUserProfile;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class UserProfileService {

    private final UserProfileRepository userProfileRepository;

    public UserProfileResponse create(UserProfileRequest request) {
        IUserProfile principal = (IUserProfile) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        UserProfile profile = UserProfile.builder()
                .id(UUID.fromString(principal.getUserId()))
                // .id(UUID.randomUUID())
                .firstName(request.firstName())
                .lastName(request.lastName())
                .description(request.description())
                .status(request.status())
                .skills(request.skills())
                .interests(request.interests())
                .build();

        userProfileRepository.save(profile);

        return toDto(profile);
    }

    public List<UserProfileResponse> getRecommendations() {

        IUserProfile principal = (IUserProfile) SecurityContextHolder
                .getContext()
                .getAuthentication()
                .getPrincipal();

        UUID userId = UUID.fromString(principal.getUserId());

        UserProfile currentUser = userProfileRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Set<String> interests = currentUser.getInterests();

        if (interests == null || interests.isEmpty()) {
            return List.of(); 
        }

        UserProfileSearchRequest request = new UserProfileSearchRequest(
                null,       
                null,        
                interests,   
                null        
        );

        List<UserProfileResponse> responses = search(request);

        return responses.stream()
                .filter(p -> !p.id().equals(currentUser.getId()))
                .toList();
    }

    public List<UserProfileResponse> findAll() {
        List<UserProfile> profiles = userProfileRepository.findAll();

        return profiles.stream()
                .map(this::toDto)
                .toList();
    }

    public List<UserProfileResponse> search(UserProfileSearchRequest request) {

        List<UserProfile> profiles = userProfileRepository.findAll(
                UserProfileSpecifications.searchByNameAndStatus(request.text(), request.status())
        );

        if (request.skills() != null && !request.skills().isEmpty()) {
            profiles = profiles.stream()
                    .filter(profile -> profile.getSkills().stream()
                            .anyMatch(skill -> request.skills().stream()
                                    .anyMatch(s -> skill.toLowerCase().contains(s.toLowerCase()))
                            )
                    )
                    .toList();
        }

        if (request.interests() != null && !request.interests().isEmpty()) {
            profiles = profiles.stream()
                    .filter(profile -> profile.getInterests().stream()
                            .anyMatch(interest -> request.interests().stream()
                                    .anyMatch(i -> interest.toLowerCase().contains(i.toLowerCase()))
                            )
                    )
                    .toList();
        }

        return profiles.stream()
                .map(this::toDto)
                .toList();
    }

    public UserProfileResponse getById(UUID id) {
        return toDto(get(id));
    }

    private UserProfile get(UUID id) {
        return userProfileRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("UserProfile not found: " + id));
    }

    public UserProfileResponse update(UUID id, UserProfileRequest request) {
        UserProfile profile = get(id);

        profile.setFirstName(request.firstName());
        profile.setLastName(request.lastName());
        profile.setDescription(request.description());
        profile.setStatus(request.status());
        profile.setSkills(request.skills());
        profile.setInterests(request.interests());

        userProfileRepository.save(profile);

        return toDto(profile);
    }

    public void delete(UUID id) {
        if (!userProfileRepository.existsById(id)) {
            throw new ResourceNotFoundException("UserProfile not found: " + id);
        }
        userProfileRepository.deleteById(id);
    }

    private UserProfileResponse toDto(UserProfile profile) {
        return new UserProfileResponse(
                profile.getId(),
                profile.getFirstName(),
                profile.getLastName(),
                profile.getDescription(),
                profile.getStatus(),
                profile.getSkills(),
                profile.getInterests()
        );
    }
}