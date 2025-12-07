package com.example.demo.repositories.specifications;

import org.springframework.data.jpa.domain.Specification;

import com.example.demo.entities.UserProfile;
import com.example.demo.entities.UserStatus;

import jakarta.persistence.criteria.Predicate;

public class UserProfileSpecifications {

    public static Specification<UserProfile> searchByNameAndStatus(String text, UserStatus status) {
        return (root, query, cb) -> {
            Predicate predicate = cb.conjunction();

            if (status != null) {
                predicate = cb.and(predicate, cb.equal(root.get("status"), status));
            }
            
            if (text != null && !text.isBlank()) {
                String pattern = "%" + text.toLowerCase() + "%";
                predicate = cb.and(predicate, cb.or(
                        cb.like(cb.lower(root.get("firstName")), pattern),
                        cb.like(cb.lower(root.get("lastName")), pattern)
                ));
            }

            query.distinct(true);
            return predicate;
        };
    }
}