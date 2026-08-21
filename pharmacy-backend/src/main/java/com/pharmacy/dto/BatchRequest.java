package com.pharmacy.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class BatchRequest {
    @NotNull
    private Long medicineId;
    private Long supplierId;
    @NotNull
    private String batchNumber;
    @NotNull
    private LocalDate expiryDate;
    @NotNull
    private Integer quantity;
    @NotNull
    private BigDecimal purchasePrice;
    @NotNull
    private BigDecimal salePrice;
}
