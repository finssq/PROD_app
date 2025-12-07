package com.example.demo.dtos.project;

import java.util.Set;

import com.example.demo.entities.ProjectStatus;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProjectRequestDto {
    private String name;
    private String description;
    private Set<String> tags;
    private ProjectStatus status;
}
