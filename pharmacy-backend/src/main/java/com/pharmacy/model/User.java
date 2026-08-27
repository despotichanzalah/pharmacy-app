package com.pharmacy.model;

import jakarta.persistence.*;
import lombok.*;
import com.fasterxml.jackson.annotation.JsonIgnore;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Data @NoArgsConstructor @AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, unique = true)
    private String email;

    @JsonIgnore
    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "role_id", nullable = false)
    private Role role;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", nullable = false)
    private Shop shop;

    // Password reset — token + expiry, both null unless a reset is in progress.
    @Column(name = "reset_token")
    private String resetToken;

    @Column(name = "reset_token_expiry")
    private LocalDateTime resetTokenExpiry;

    // Approval gate for staff joining an existing shop — null/true means approved (this also
    // grandfathers every account that existed before this feature shipped, since their DB
    // column will be NULL, not false). Only set explicitly to false when someone joins a shop
    // as non-founding staff, until the shop's Admin approves them.
    @Column(name = "approved")
    private Boolean approved;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();
}
