package com.example.demo.services;

import java.util.HashSet;
import java.util.List;
import java.util.Random;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.example.demo.dtos.UserProfile.UserProfileResponse;
import com.example.demo.dtos.project.ParticipantFilterRequest;
import com.example.demo.dtos.project.ProjectRequestDto;
import com.example.demo.dtos.project.ProjectResponse;
import com.example.demo.dtos.project.ProjectSearchRequest;
import com.example.demo.entities.Project;
import com.example.demo.entities.ProjectStatus;
import com.example.demo.entities.UserProfile;
import com.example.demo.exception.exceptions.AccessDeniedException;
import com.example.demo.exception.exceptions.ResourceNotFoundException;
import com.example.demo.repositories.ProjectRepository;
import com.example.demo.repositories.UserProfileRepository;
import com.example.demo.repositories.specifications.ProjectSpecification;
import com.example.demo.security.IUserProfile;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ProjectService {

    private final ProjectRepository projectRepository;
    private final UserProfileRepository userProfileRepository;

    private UUID getCurrentUserId() {
        IUserProfile principal =
                (IUserProfile) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return UUID.fromString(principal.getUserId());
    }

    public ProjectResponse create(ProjectRequestDto request) {
        UUID userId = getCurrentUserId();

        UserProfile organizer = userProfileRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        Project project = new Project();
        project.setName(request.getName());
        project.setDescription(request.getDescription());
        project.setTags(request.getTags() != null ? request.getTags() : new HashSet<>());
        project.setOrganizer(organizer);
        project.setInvitationCode(generateFormattedCode());
        project.setStatus(request.getStatus());

        return toDto(projectRepository.save(project));
    }

    public List<ProjectResponse> findAll() {
        return projectRepository.findAll().stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public List<ProjectResponse> getRecommendations() {

        IUserProfile principal = (IUserProfile) SecurityContextHolder
                .getContext()
                .getAuthentication()
                .getPrincipal();

        UUID userId = UUID.fromString(principal.getUserId());

        UserProfile currentUser = userProfileRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Set<String> userInterests = currentUser.getInterests();

        if (userInterests == null || userInterests.isEmpty()) {
            return List.of();
        }

        ProjectSearchRequest request = new ProjectSearchRequest(
                null,
                userInterests,
                false
        );

        return search(request);
    }

    public ProjectResponse getById(Long id, ParticipantFilterRequest filter) {
        Project project = projectRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found: " + id));

        Set<UserProfile> participants = new HashSet<>(project.getParticipants());

        if (filter != null && filter.skills() != null && !filter.skills().isEmpty()) {
            participants = participants.stream()
                    .filter(p -> p.getSkills().stream()
                            .anyMatch(skill -> filter.skills().stream()
                                    .anyMatch(req -> skill.toLowerCase().contains(req.toLowerCase()))
                            )
                    )
                    .collect(Collectors.toSet());
        }

        if (filter != null && filter.interests() != null && !filter.interests().isEmpty()) {
            participants = participants.stream()
                    .filter(p -> p.getInterests().stream()
                            .anyMatch(interest -> filter.interests().stream()
                                    .anyMatch(req -> interest.toLowerCase().contains(req.toLowerCase()))
                            )
                    )
                    .collect(Collectors.toSet());
        }

        return toDto(project, participants);
    }

    public ProjectResponse update(Long id, ProjectRequestDto request) {
        Project project = projectRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found: " + id));

        project.setName(request.getName());
        project.setDescription(request.getDescription());
        project.setTags(request.getTags());
        project.setStatus(request.getStatus());

        return toDto(projectRepository.save(project));
    }

    public void delete(Long id) {
        if (!projectRepository.existsById(id)) {
            throw new ResourceNotFoundException("Project not found: " + id);
        }
        projectRepository.deleteById(id);
    }

        public ProjectResponse addParticipant(Long projectId, String invitationCode) {
                Project project = projectRepository.findById(projectId)
                        .orElseThrow(() -> new ResourceNotFoundException("Project not found: " + projectId));

                UUID userId = getCurrentUserId();

                UserProfile participant = userProfileRepository.findById(userId)
                        .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

                if (project.getStatus() == ProjectStatus.PUBLIC) {
                        project.getParticipants().add(participant);
                        return toDto(projectRepository.save(project));
                }

                if (project.getInvitationCode() == null || !project.getInvitationCode().equals(invitationCode)) {
                        throw new AccessDeniedException("Неверный код приглашения");
                }

                project.getParticipants().add(participant);
                return toDto(projectRepository.save(project));
        }

    public ProjectResponse removeParticipant(Long id) {
        Project project = projectRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found: " + id));

        UUID userId = getCurrentUserId();

        UserProfile participant = userProfileRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        project.getParticipants().remove(participant);

        return toDto(projectRepository.save(project));
    }

    public List<ProjectResponse> search(ProjectSearchRequest request) {

        List<Project> projects = projectRepository.findAll(ProjectSpecification.search(request));

        if (request.tags() != null && !request.tags().isEmpty()) {
            projects = projects.stream()
                    .filter(project -> request.tags().stream()
                            .anyMatch(tag -> project.getTags().stream()
                                    .anyMatch(t -> t.toLowerCase().contains(tag.toLowerCase()))
                            )
                    )
                    .collect(Collectors.toList());
        }

        if (Boolean.TRUE.equals(request.onlyMyProjects())) {
            UUID currentUserId = getCurrentUserId();

            projects = projects.stream()
                    .filter(project -> project.getOrganizer() != null &&
                            project.getOrganizer().getId().equals(currentUserId))
                    .collect(Collectors.toList());
        }

        return projects.stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public String updateInvitationCode(Long projectId) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found: " + projectId));

        String newCode = generateFormattedCode();
        project.setInvitationCode(newCode);
        projectRepository.save(project);

        return newCode;
    }

    private String generateFormattedCode() {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        Random random = new Random();
        return String.format("%c%c-%c%c-%c%c",
                chars.charAt(random.nextInt(chars.length())),
                chars.charAt(random.nextInt(chars.length())),
                chars.charAt(random.nextInt(chars.length())),
                chars.charAt(random.nextInt(chars.length())),
                chars.charAt(random.nextInt(chars.length())),
                chars.charAt(random.nextInt(chars.length()))
        );
    }

    public ProjectResponse likeProject(Long projectId) {
        UUID currentUserId = getCurrentUserId();

        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found: " + projectId));

        UserProfile user = userProfileRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + currentUserId));

        project.getLikes().add(user);

        return toDto(projectRepository.save(project), project.getParticipants());
    }

    public ProjectResponse unlikeProject(Long projectId) {
        UUID currentUserId = getCurrentUserId();

        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found: " + projectId));

        UserProfile user = userProfileRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + currentUserId));

        project.getLikes().remove(user);

        return toDto(projectRepository.save(project), project.getParticipants());
    }





    private ProjectResponse toDto(Project project) {
        return toDto(project, project.getParticipants());
    }

    private ProjectResponse toDto(Project project, Set<UserProfile> participants) {
        UUID currentUserId = getCurrentUserId();

        String code = project.getOrganizer().getId().equals(currentUserId) 
                ? project.getInvitationCode() 
                : null;

        boolean liked = project.getLikes().stream()
            .anyMatch(u -> u.getId().equals(currentUserId));

        return new ProjectResponse(
                project.getId(),
                UserProfileResponse.from(project.getOrganizer(), currentUserId),
                project.getName(),
                project.getDescription(),
                project.getTags(),
                participants.stream()
                        .map(p -> UserProfileResponse.from(p, currentUserId))
                        .collect(Collectors.toSet()),
                project.getLikes().size(),
                liked,
                code,
                project.getStatus()
        );
    }
}

// 3T-7Y-CL
