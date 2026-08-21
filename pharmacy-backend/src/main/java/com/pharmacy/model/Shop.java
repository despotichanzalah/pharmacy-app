package com.pharmacy.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "shops")
@Data @NoArgsConstructor @AllArgsConstructor
public class Shop {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String address;

    private String contact;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();
}
