package com.example.demo.entities;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "user_profiles")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserProfile {

        @Id
        @Column(columnDefinition = "uuid")
        private UUID id;

        private String firstName;
        private String lastName;

        @Column(length = 1000)
        private String description;

        @Enumerated(EnumType.STRING)
        private UserStatus status;

        @ElementCollection(fetch = FetchType.LAZY)
        @CollectionTable(
                name = "user_profile_skills",
                joinColumns = @JoinColumn(name = "user_profile_id")
        )
        @Column(name = "skill")
        @Builder.Default
        private Set<String> skills = new HashSet<>();

        @ElementCollection(fetch = FetchType.LAZY)
        @CollectionTable(
                name = "user_profile_interests",
                joinColumns = @JoinColumn(name = "user_profile_id")
        )
        @Column(name = "interest")
        @Builder.Default
        private Set<String> interests = new HashSet<>();

        @ManyToMany
        @JoinTable(
                name = "user_profile_stars",
                joinColumns = @JoinColumn(name = "target_user_id"),     
                inverseJoinColumns = @JoinColumn(name = "from_user_id") 
        )
        @Builder.Default
        private Set<UserProfile> stars = new HashSet<>();
}