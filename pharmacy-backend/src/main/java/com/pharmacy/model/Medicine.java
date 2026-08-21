package com.pharmacy.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "medicines")
@Data @NoArgsConstructor @AllArgsConstructor
public class Medicine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name; // brand / company name, e.g. "Panadol Extra"

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", nullable = false)
    private Shop shop;

    private String unit; // tablet, syrup, injection, box

    @Column(name = "reorder_level")
    private Integer reorderLevel = 10; // low-stock alert threshold

    // A medicine can contain more than one active formula (e.g. Panadol Extra = Paracetamol + Caffeine).
    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
        name = "medicine_generics",
        joinColumns = @JoinColumn(name = "medicine_id"),
        inverseJoinColumns = @JoinColumn(name = "generic_id")
    )
    private Set<Generic> generics = new HashSet<>();
}
