package com.pharmacy.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class PurchaseItemRequest {
    @NotNull
    private Long medicineId;
    @NotNull
    private String batchNumber;
    @NotNull
    private Integer quantity;
    @NotNull
    private BigDecimal unitPrice;
    @NotNull
    private LocalDate expiryDate;
}
