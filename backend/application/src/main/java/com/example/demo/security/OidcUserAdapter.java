package com.example.demo.security;

import java.util.Collection;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.core.oidc.OidcIdToken;
import org.springframework.security.oauth2.core.oidc.OidcUserInfo;
import org.springframework.security.oauth2.core.oidc.user.DefaultOidcUser;

public class OidcUserAdapter extends DefaultOidcUser implements IUserProfile {

    private final String userId;
    private final String fullName;
    private final String email;

    public OidcUserAdapter(Collection<? extends GrantedAuthority> authorities, OidcIdToken idToken, OidcUserInfo userInfo) {
        super(authorities, idToken, userInfo);
        
        this.userId = idToken.getSubject();
        this.fullName = userInfo.getFullName() != null ? userInfo.getFullName() : userInfo.getGivenName() + " " + userInfo.getFamilyName();
        this.email = userInfo.getEmail();
    }

    @Override
    public String getUserId() {
        return this.userId;
    }

    @Override
    public String getEmail() {
        return this.email;
    }

    @Override
    public String getFullName() {
        return this.fullName;
    }

    @Override
    public String getName() {
        return getPreferredUsername(); 
    }

    @Override
    public String getUsername() {
        return getPreferredUsername(); 
    }
}