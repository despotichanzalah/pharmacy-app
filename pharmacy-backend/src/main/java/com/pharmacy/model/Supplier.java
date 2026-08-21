package com.pharmacy.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "suppliers")
@Data @NoArgsConstructor @AllArgsConstructor
public class Supplier {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String contact;

    private String address;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", nullable = false)
    private Shop shop;
}
