package com.pharmacy.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "return_items")
@Data @NoArgsConstructor @AllArgsConstructor
public class ReturnItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "return_id", nullable = false)
    private Return returnRef;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sale_item_id", nullable = false)
    private SaleItem saleItem;

    @Column(nullable = false)
    private Integer quantity;
}
