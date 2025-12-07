package com.example.demo.entities;

import java.util.HashSet;
import java.util.Set;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
@Table(name = "projects")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Project {

        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        private Long id;

        @ManyToOne
        @JoinColumn(name = "organizer_id", nullable = false)
        private UserProfile organizer;

        private String name;

        @Column(length = 2000)
        private String description;

        @ElementCollection
        @CollectionTable(
                name = "project_tags",
                joinColumns = @JoinColumn(name = "project_id")
        )
        @Column(name = "tag")
        private Set<String> tags = new HashSet<>();

        @ManyToMany
        @JoinTable(
                name = "project_participants",
                joinColumns = @JoinColumn(name = "project_id"),
                inverseJoinColumns = @JoinColumn(name = "user_profile_id")
        )
        private Set<UserProfile> participants = new HashSet<>();
        private String invitationCode; 

        @ManyToMany
        @JoinTable(
                name = "project_likes",
                joinColumns = @JoinColumn(name = "project_id"),
                inverseJoinColumns = @JoinColumn(name = "user_profile_id")
        )
        private Set<UserProfile> likes = new HashSet<>();

        @Enumerated(EnumType.STRING)
        private ProjectStatus status;
}
