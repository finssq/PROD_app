package com.example.demo.security;

import java.util.Collection;

import org.springframework.security.core.GrantedAuthority;

public interface IUserProfile {
    String getUserId();
    String getUsername();
    String getEmail();
    String getFullName();
    Collection<? extends GrantedAuthority> getAuthorities();
}
