package com.example.demo.services;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.example.demo.dtos.UserProfile.UserProfileResponse;
import com.example.demo.dtos.event.EventRequestDto;
import com.example.demo.dtos.event.EventResponse;
import com.example.demo.dtos.event.EventSearchRequest;
import com.example.demo.dtos.event.ParticipantFilterRequest;
import com.example.demo.entities.Event;
import com.example.demo.entities.UserProfile;
import com.example.demo.exception.exceptions.ResourceNotFoundException;
import com.example.demo.repositories.EventRepository;
import com.example.demo.repositories.UserProfileRepository;
import com.example.demo.repositories.specifications.EventSpecification;
import com.example.demo.security.IUserProfile;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class EventService {

    private final EventRepository eventRepository;
    private final UserProfileRepository userProfileRepository;

    public EventResponse create(EventRequestDto request) {
        UUID userId = getCurrentUserId();

        UserProfile organizer = userProfileRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        Event event = new Event();
        event.setName(request.getName());
        event.setDescription(request.getDescription());
        event.setEventTime(request.getEventTime());
        event.setPlace(request.getPlace());
        event.setTags(request.getTags() != null ? request.getTags() : new HashSet<>());
        event.setOrganizer(organizer);

        Event saved = eventRepository.save(event);
        return toDto(saved);
    }

    public List<EventResponse> findAll() {
        return eventRepository.findAll().stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public List<EventResponse> getRecommendations() {

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

        EventSearchRequest request = new EventSearchRequest(
                null,        
                null,        
                null,       
                userInterests,
                false
        );

        List<EventResponse> events = search(request);

        return events;
    }

    public EventResponse getById(Long id, ParticipantFilterRequest filter) {

        Event event = eventRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found with id: " + id));

        Set<UserProfile> participants = new HashSet<>(event.getParticipants());

        if (filter != null && filter.skills() != null && !filter.skills().isEmpty()) {
            participants = participants.stream()
                    .filter(p -> p.getSkills().stream()
                            .anyMatch(skill -> filter.skills().stream()
                                    .anyMatch(requestSkill -> 
                                            skill.toLowerCase().contains(requestSkill.toLowerCase())
                                    )
                            )
                    )
                    .collect(Collectors.toSet());
        }

        if (filter != null && filter.interests() != null && !filter.interests().isEmpty()) {
            participants = participants.stream()
                    .filter(p -> p.getInterests().stream()
                            .anyMatch(interest -> filter.interests().stream()
                                    .anyMatch(reqInterest ->
                                            interest.toLowerCase().contains(reqInterest.toLowerCase())
                                    )
                            )
                    )
                    .collect(Collectors.toSet());
        }

        return toDto(event, participants);
    }

    public EventResponse update(Long id, EventRequestDto request) {
        Event event = eventRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found with id: " + id));

        event.setName(request.getName());
        event.setDescription(request.getDescription());
        event.setEventTime(request.getEventTime());
        event.setPlace(request.getPlace());
        event.setTags(request.getTags());

        Event updated = eventRepository.save(event);
        return toDto(updated);
    }

    public void delete(Long id) {
        if (!eventRepository.existsById(id)) {
            throw new ResourceNotFoundException("Event not found with id: " + id);
        }
        eventRepository.deleteById(id);
    }

    public EventResponse addParticipant(Long eventId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found with id: " + eventId));

        UUID userId = getCurrentUserId();

        UserProfile participant = userProfileRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        event.getParticipants().add(participant);
        return toDto(eventRepository.save(event));
    }

    public EventResponse removeParticipant(Long eventId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event not found with id: " + eventId));

        UUID userId = getCurrentUserId();

        UserProfile participant = userProfileRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        event.getParticipants().remove(participant);
        return toDto(eventRepository.save(event));
    }

    public List<EventResponse> search(EventSearchRequest request) {
        List<Event> events = eventRepository.findAll(EventSpecification.search(request));

        if (request.tags() != null && !request.tags().isEmpty()) {
            events = events.stream()
                    .filter(event -> request.tags().stream()
                            .anyMatch(tag -> event.getTags().stream()
                                    .anyMatch(eventTag ->
                                            eventTag.toLowerCase().contains(tag.toLowerCase())
                                    )
                            )
                    )
                    .collect(Collectors.toList());
        }

        if (Boolean.TRUE.equals(request.onlyMyEvents())) {

        UUID currentUserId = getCurrentUserId();

        events = events.stream()
                .filter(event -> event.getOrganizer() != null &&
                        event.getOrganizer().getId().equals(currentUserId))
                .collect(Collectors.toList());
        }

        return events.stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

        public EventResponse likeEvent(Long eventId) {

                Event event = eventRepository.findById(eventId)
                        .orElseThrow(() -> new ResourceNotFoundException("Event not found: " + eventId));

                UUID userId = getCurrentUserId();

                UserProfile user = userProfileRepository.findById(userId)
                        .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

                event.getLikes().add(user);

                return toDto(eventRepository.save(event));
        }

        public EventResponse unlikeEvent(Long eventId) {

                Event event = eventRepository.findById(eventId)
                        .orElseThrow(() -> new ResourceNotFoundException("Event not found: " + eventId));

                UUID userId = getCurrentUserId();

                UserProfile user = userProfileRepository.findById(userId)
                        .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

                event.getLikes().remove(user);

                return toDto(eventRepository.save(event));
        }

        private UUID getCurrentUserId() {
                IUserProfile principal =
                        (IUserProfile) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                return UUID.fromString(principal.getUserId());
        }

        private EventResponse toDto(Event event) {
                UUID currentUserId = getCurrentUserId();

                boolean liked = event.getLikes().stream()
                        .anyMatch(u -> u.getId().equals(currentUserId));

                return new EventResponse(
                        event.getId(),
                        UserProfileResponse.from(event.getOrganizer(), currentUserId),
                        event.getName(),
                        event.getDescription(),
                        event.getEventTime(),
                        event.getPlace(),
                        event.getTags(),
                        event.getParticipants().stream()
                                .map(p -> UserProfileResponse.from(p, currentUserId))
                                .collect(Collectors.toSet()),
                        event.getLikes().size(),
                        liked
                );
                }

        private EventResponse toDto(Event event, Set<UserProfile> filteredParticipants) {
                UUID currentUserId = getCurrentUserId();

                boolean liked = event.getLikes().stream()
                        .anyMatch(u -> u.getId().equals(currentUserId));

                return new EventResponse(
                        event.getId(),
                        UserProfileResponse.from(event.getOrganizer(), currentUserId),
                        event.getName(),
                        event.getDescription(),
                        event.getEventTime(),
                        event.getPlace(),
                        event.getTags(),
                        filteredParticipants.stream()
                                .map(p -> UserProfileResponse.from(p, currentUserId))
                                .collect(Collectors.toSet()),
                        event.getLikes().size(),
                        liked
                );
        }
}