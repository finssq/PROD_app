package com.example.demo.dtos.event;

import java.util.Set;

public record ParticipantFilterRequest(
    Set<String> skills,
    Set<String> interests
) {}
