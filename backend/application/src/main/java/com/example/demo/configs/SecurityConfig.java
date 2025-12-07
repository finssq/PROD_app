package com.example.demo.configs;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.client.oidc.userinfo.OidcUserRequest;
import org.springframework.security.oauth2.client.oidc.userinfo.OidcUserService;
import org.springframework.security.oauth2.client.oidc.web.logout.OidcClientInitiatedLogoutSuccessHandler;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserService;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.logout.LogoutSuccessHandler;
import org.springframework.web.cors.CorsConfiguration;

import com.example.demo.security.CustomJwtAuthentication;
import com.example.demo.security.CustomUserPrincipal;
import com.example.demo.security.OidcUserAdapter;

import lombok.RequiredArgsConstructor;

@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final ClientRegistrationRepository clientRegistrationRepository;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {    
        http.cors(cors -> cors.configurationSource(request -> new CorsConfiguration().applyPermitDefaultValues()));
        http.oauth2ResourceServer(oauth2 -> oauth2
            .jwt(jwt -> jwt
                .jwtAuthenticationConverter(customJwtAuthenticationConverter()) 
            )
        );
        http.oauth2Login(oauth2 -> oauth2
            .authorizationEndpoint(authorization -> authorization
                .baseUri("/oauth2/authorization")
            )
        );
        http.logout(logout -> logout
                .logoutUrl("/logout") 
                .invalidateHttpSession(true) 
                .clearAuthentication(true) 
                .logoutSuccessHandler(oidcLogoutSuccessHandler())
            );

        return http
                .csrf(csrf -> csrf.disable())
                // .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(c -> c
                    .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                    .requestMatchers("/error").permitAll()
                    .requestMatchers("/api/**").authenticated()
                    .requestMatchers("/api/view/posts/**").authenticated()
                    .requestMatchers("/api/security/profile").authenticated()
                    .requestMatchers("/api/security/user").hasRole("USER")
                    .requestMatchers("/api/security/admin").hasRole("ADMIN")
                    .requestMatchers("/api/security/root").hasRole("ROOT")
                    .anyRequest().permitAll()
                )
                .build();
    }

    @Bean
    public Converter<Jwt, AbstractAuthenticationToken> customJwtAuthenticationConverter() {
        return jwt -> {
            Collection<GrantedAuthority> authorities = extractAuthorities(jwt);
            String userId = jwt.getClaimAsString("sub"); 
            String username = jwt.getClaimAsString("preferred_username");
            String email = jwt.getClaimAsString("email");
            String fullName = jwt.getClaimAsString("name"); 

            CustomUserPrincipal principal = new CustomUserPrincipal(
                userId, username, email, fullName, authorities
            );

            return new CustomJwtAuthentication(principal, jwt, authorities);
        };
    }

    @Bean
    public OAuth2UserService<OidcUserRequest, OidcUser> oAuth2UserService() {
        var oidcUserService = new OidcUserService();
        return userRequest -> {
            var oidcUser = oidcUserService.loadUser(userRequest);
            List<GrantedAuthority> authorities = new ArrayList<>();

            var roles = Optional.ofNullable(oidcUser.getClaimAsStringList("spring_sec_roles")).orElse(Collections.emptyList());
            
            roles.stream()
                .filter(role -> role.startsWith("ROLE_"))
                .map(SimpleGrantedAuthority::new)
                .forEach(authorities::add);
                
            return new OidcUserAdapter(authorities, oidcUser.getIdToken(), oidcUser.getUserInfo());
        };
    }

    private LogoutSuccessHandler oidcLogoutSuccessHandler() {
        OidcClientInitiatedLogoutSuccessHandler oidcLogoutSuccessHandler =
                new OidcClientInitiatedLogoutSuccessHandler(this.clientRegistrationRepository);

        oidcLogoutSuccessHandler.setPostLogoutRedirectUri("{baseUrl}"); 

        return oidcLogoutSuccessHandler;
    }

    private Collection<GrantedAuthority> extractAuthorities(Jwt jwt) {
        var jwtGrantedAuthoritiesConverter = new JwtGrantedAuthoritiesConverter();
        var authorities = jwtGrantedAuthoritiesConverter.convert(jwt);
        var roles = jwt.getClaimAsStringList("spring_sec_roles");

        return Stream.concat(
            authorities.stream(),
            roles.stream()
                .filter(role -> role.startsWith("ROLE_"))
                .map(SimpleGrantedAuthority::new)
                .map(GrantedAuthority.class::cast)
        ).collect(Collectors.toList());
    }
} 
