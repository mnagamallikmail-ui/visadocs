package com.provaluer.security;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import java.util.Collection;
import java.util.Collections;

public class UserDetailsImpl implements UserDetails {
    private Long id;
    private String username;
    private String email;
    @JsonIgnore
    private String password;
    private Collection<? extends GrantedAuthority> authorities;
    private boolean locked;
    private boolean deleted;

    public UserDetailsImpl(Long id, String username, String email, String password,
                           Collection<? extends GrantedAuthority> authorities,
                           boolean locked, boolean deleted) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.password = password;
        this.authorities = authorities;
        this.locked = locked;
        this.deleted = deleted;
    }

    public UserDetailsImpl(Long id, String email, String password,
                           Collection<? extends GrantedAuthority> authorities,
                           boolean locked, boolean deleted) {
        this(id, email != null && email.contains("@") ? email.substring(0, email.indexOf('@')) : email,
             email, password, authorities, locked, deleted);
    }

    public static UserDetailsImpl build(User user) {
        String roleAuthority;
        if (user.getRole() == UserRole.SUPER_ADMIN) {
            roleAuthority = "ROLE_SUPER_ADMIN";
        } else if (user.getRole() == UserRole.ADMIN) {
            roleAuthority = "ROLE_ADMIN";
        } else {
            roleAuthority = "ROLE_" + user.getRole().name();
        }
        SimpleGrantedAuthority authority = new SimpleGrantedAuthority(roleAuthority);
        return new UserDetailsImpl(
                user.getId(),
                user.getUsername(),
                user.getEmail(),
                user.getPassword(),
                Collections.singletonList(authority),
                user.isLocked(),
                user.isDeleted()
        );
    }

    public Long getId() { return id; }

    public String getEmail() { return email; }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() { return authorities; }

    @Override
    public String getPassword() { return password; }

    @Override
    public String getUsername() { return username != null ? username : email; }

    @Override
    public boolean isAccountNonExpired() { return true; }

    @Override
    public boolean isAccountNonLocked() { return !locked; }

    @Override
    public boolean isCredentialsNonExpired() { return true; }

    @Override
    public boolean isEnabled() { return !deleted; }
}
