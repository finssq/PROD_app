package com.example.demo.dtos.project;

import java.util.Set;

public record ProjectSearchRequest(
    String name,
    Set<String> tags,
    Boolean onlyMyProjects
) {}