package com.example.demo.repositories.specifications;

import org.springframework.data.jpa.domain.Specification;

import com.example.demo.dtos.project.ProjectSearchRequest;
import com.example.demo.entities.Project;

import jakarta.persistence.criteria.Predicate;

public class ProjectSpecification {

    public static Specification<Project> search(ProjectSearchRequest request) {
        return (root, query, cb) -> {

            Predicate predicate = cb.conjunction();

            if (request.name() != null && !request.name().isBlank()) {
                String pattern = "%" + request.name().toLowerCase() + "%";
                predicate = cb.and(predicate,
                        cb.like(cb.lower(root.get("name")), pattern));
            }

            query.distinct(true);
            return predicate;
        };
    }
}
