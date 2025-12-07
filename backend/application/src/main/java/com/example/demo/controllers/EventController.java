package com.example.demo.controllers;

import java.util.List;
import java.util.Set;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dtos.event.EventRequestDto;
import com.example.demo.dtos.event.EventResponse;
import com.example.demo.dtos.event.EventSearchRequest;
import com.example.demo.dtos.event.ParticipantFilterRequest;
import com.example.demo.services.EventService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;

    @Operation(
            summary = "Create a new event",
            description = "Creates a new event with name, description, eventTime, place, and tags. The organizer is set from the authenticated user."
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Event successfully created",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = EventResponse.class)
                    )
            ),
            @ApiResponse(responseCode = "400", description = "Invalid request data", content = @Content),
            @ApiResponse(responseCode = "500", description = "Internal server error", content = @Content)
    })
    @PostMapping
    public ResponseEntity<EventResponse> create(
            @Valid @RequestBody EventRequestDto request
    ) {
        return ResponseEntity.ok(eventService.create(request));
    }

    @GetMapping("/recommendations")
    public ResponseEntity<List<EventResponse>> getEventRecommendations() {
        return ResponseEntity.ok(eventService.getRecommendations());
    }

    @GetMapping
    public ResponseEntity<List<EventResponse>> findAll() {
        return ResponseEntity.ok(eventService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<EventResponse> getById(
            @PathVariable Long id,
            @RequestParam(required = false) Set<String> skills,
            @RequestParam(required = false) Set<String> interests
    ) {
        ParticipantFilterRequest filter = new ParticipantFilterRequest(skills, interests);
        return ResponseEntity.ok(eventService.getById(id, filter));
    }

    @PutMapping("/{id}")
    public ResponseEntity<EventResponse> update(@PathVariable Long id, @RequestBody EventRequestDto request) {
        return ResponseEntity.ok(eventService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        eventService.delete(id);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{id}/participants")
    public ResponseEntity<EventResponse> addParticipant(@PathVariable Long id) {
        return ResponseEntity.ok(eventService.addParticipant(id));
    }

    @DeleteMapping("/{id}/participants")
    public ResponseEntity<EventResponse> removeParticipant(@PathVariable Long id) {
        return ResponseEntity.ok(eventService.removeParticipant(id));
    }

    @Operation(
        summary = "Search events",
        description = "Searches for events by name, eventTime, place (via Specification) and tags (filtered manually)."
    )
    @ApiResponses(value = {
        @ApiResponse(
            responseCode = "200",
            description = "List of events matching the search criteria",
            content = @Content(
                mediaType = "application/json",
                array = @ArraySchema(schema = @Schema(implementation = EventResponse.class))
            )
        ),
        @ApiResponse(responseCode = "400", description = "Invalid search request", content = @Content),
        @ApiResponse(responseCode = "500", description = "Internal server error", content = @Content)
    })
    @PostMapping("/search")
    public ResponseEntity<List<EventResponse>> search(
            @RequestBody EventSearchRequest request
    ) {
        return ResponseEntity.ok(eventService.search(request));
    }

    @PostMapping("/{id}/like")
    public EventResponse likeEvent(@PathVariable Long id) {
        return eventService.likeEvent(id);
    }

    @DeleteMapping("/{id}/like")
    public EventResponse unlikeEvent(@PathVariable Long id) {
        return eventService.unlikeEvent(id);
    }
}
