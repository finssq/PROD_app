package com.example.demo.controllers;

import java.util.List;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dtos.project.ParticipantFilterRequest;
import com.example.demo.dtos.project.ProjectRequestDto;
import com.example.demo.dtos.project.ProjectResponse;
import com.example.demo.dtos.project.ProjectSearchRequest;
import com.example.demo.services.ProjectService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/projects")
@RequiredArgsConstructor
public class ProjectController {

    private final ProjectService projectService;

    @PostMapping
    public ProjectResponse create(@RequestBody ProjectRequestDto request) {
        return projectService.create(request);
    }

    @GetMapping
    public List<ProjectResponse> findAll() {
        return projectService.findAll();
    }

    @GetMapping("/{id}")
    public ProjectResponse getById(
            @PathVariable Long id,
            @RequestBody(required = false) ParticipantFilterRequest filter
    ) {
        return projectService.getById(id, filter);
    }

    @PutMapping("/{id}")
    public ProjectResponse update(
            @PathVariable Long id,
            @RequestBody ProjectRequestDto request
    ) {
        return projectService.update(id, request);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        projectService.delete(id);
    }

    @PostMapping("/{id}/participants")
    public ProjectResponse addParticipant(
            @PathVariable Long id,
            @RequestParam(name = "code", required = false) String invitationCode 
    ) {
        return projectService.addParticipant(id, invitationCode);
    }

    @DeleteMapping("/{id}/participants")
    public ProjectResponse removeParticipant(@PathVariable Long id) {
        return projectService.removeParticipant(id);
    }

    @PostMapping("/search")
    public List<ProjectResponse> search(@RequestBody ProjectSearchRequest request) {
        return projectService.search(request);
    }

    @GetMapping("/recommendations")
    public List<ProjectResponse> getRecommendations() {
        return projectService.getRecommendations();
    }

    @PostMapping("/{id}/like")
    public ProjectResponse likeProject(@PathVariable Long id) {
        return projectService.likeProject(id);
    }

    @DeleteMapping("/{id}/unlike")
    public ProjectResponse unlikeProject(@PathVariable Long id) {
        return projectService.unlikeProject(id);
    }

    @PutMapping("/{id}/invitation-code")
    public String updateInvitationCode(@PathVariable Long id) {
        return projectService.updateInvitationCode(id);
    }
}

