package com.example.demo.repositories.specifications;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

import org.springframework.data.jpa.domain.Specification;

import com.example.demo.dtos.event.EventSearchRequest;
import com.example.demo.entities.Event;

import jakarta.persistence.criteria.Predicate;

public class EventSpecification {

    public static Specification<Event> search(EventSearchRequest request) {
        return (root, query, cb) -> {

            Predicate predicate = cb.conjunction();

            if (request.name() != null && !request.name().isBlank()) {
                String pattern = "%" + request.name().toLowerCase() + "%";
                predicate = cb.and(
                        predicate,
                        cb.like(cb.lower(root.get("name")), pattern)
                );
            }

            if (request.place() != null && !request.place().isBlank()) {
                String pattern = "%" + request.place().toLowerCase() + "%";
                predicate = cb.and(
                        predicate,
                        cb.like(cb.lower(root.get("place")), pattern)
                );
            }

            // if (request.eventTime() != null && !request.eventTime().isBlank()) {
            //     String pattern = "%" + request.eventTime().toLowerCase() + "%";

            //     Expression<String> eventTimeStr = cb.function(
            //             "CAST",
            //             String.class,
            //             root.get("eventTime"),
            //             cb.literal("VARCHAR")
            //     );

            //     predicate = cb.and(
            //             predicate,
            //             cb.like(cb.lower(eventTimeStr), pattern)
            //     );
            // }

            if (request.eventTime() != null && !request.eventTime().isBlank()) {
                Instant instant = Instant.parse(request.eventTime());
                LocalDateTime eventTime = LocalDateTime.ofInstant(instant, ZoneOffset.UTC);

                LocalDateTime startOfDay = eventTime.toLocalDate().atStartOfDay();
                LocalDateTime endOfDay = eventTime.toLocalDate().atTime(23, 59, 59);

                predicate = cb.and(
                    predicate,
                    cb.between(root.get("eventTime"), startOfDay, endOfDay)
            );
        }

            query.distinct(true);

            return predicate;
        };
    }
    
    // public static Specification<Event> search(EventSearchRequest request) {
    //     return (root, query, cb) -> {

    //         Predicate predicate = cb.conjunction();

    //         // --- name ---
    //         if (request.name() != null && !request.name().isBlank()) {
    //             String pattern = "%" + request.name().toLowerCase() + "%";
    //             predicate = cb.and(predicate,
    //                     cb.like(cb.lower(root.get("name")), pattern)
    //             );
    //         }

    //         // --- place ---
    //         if (request.place() != null && !request.place().isBlank()) {
    //             String pattern = "%" + request.place().toLowerCase() + "%";
    //             predicate = cb.and(predicate,
    //                     cb.like(cb.lower(root.get("place")), pattern)
    //             );
    //         }

    //         // --- eventTime as string via TO_CHAR ---
    //         if (request.eventTime() != null && !request.eventTime().isBlank()) {

    //             String pattern = "%" + request.eventTime().toLowerCase() + "%";

    //             Expression<String> formatted = cb.function(
    //                     "to_char",
    //                     String.class,
    //                     root.get("eventTime"),
    //                     cb.literal("YYYY-MM-DD HH24:MI:SS")
    //             );

    //             predicate = cb.and(predicate,
    //                     cb.like(cb.lower(formatted), pattern)
    //             );
    //         }

    //         query.distinct(true);
    //         return predicate;
    //     };
    // }
}