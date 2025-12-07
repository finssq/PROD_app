package com.example.demo.entities;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "events")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Event {

        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        private Long id;

        @ManyToOne
        @JoinColumn(name = "organizer_id", nullable = false)
        private UserProfile organizer;

        private String name;

        @Column(length = 2000)
        private String description;

        private LocalDateTime  eventTime;

        private String place;

        @ElementCollection
        @CollectionTable(
                name = "event_tags",
                joinColumns = @JoinColumn(name = "event_id")
                )
        @Column(name = "tag")
        private Set<String> tags = new HashSet<>();

        @ManyToMany
        @JoinTable(
                name = "event_participants",
                joinColumns = @JoinColumn(name = "event_id"),
                inverseJoinColumns = @JoinColumn(name = "user_profile_id")
        )
        private Set<UserProfile> participants = new HashSet<>();
}
