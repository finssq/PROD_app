package com.example.demo.dtos.project;

import java.util.Set;

public record ParticipantFilterRequest(
    Set<String> skills,
    Set<String> interests
) {}
