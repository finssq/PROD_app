package com.example.demo.dtos.event;

import java.util.Set;

public record EventSearchRequest(
    String name,
    String eventTime,
    String place,
    Set<String> tags
) {}
