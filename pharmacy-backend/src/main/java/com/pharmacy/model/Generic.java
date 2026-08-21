package com.pharmacy.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "generics")
@Data @NoArgsConstructor @AllArgsConstructor
public class Generic {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name; // e.g. Paracetamol, Amoxicillin
}
