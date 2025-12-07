package com.example.demo.security;

import java.util.Collection;

import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

public class CustomJwtAuthentication extends AbstractAuthenticationToken {
    
    private final CustomUserPrincipal principal;
    private final Jwt credentials;

    public CustomJwtAuthentication(CustomUserPrincipal principal, Jwt credentials, Collection<? extends GrantedAuthority> authorities) {
        super(authorities);

        this.principal = principal;
        this.credentials = credentials;

        setAuthenticated(true); 
    }

    @Override
    public Object getCredentials() {
        return credentials; 
    }

    @Override
    public Object getPrincipal() {
        return principal; 
    }
}