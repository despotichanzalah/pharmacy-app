package com.pharmacy.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class SaleItemRequest {
    @NotNull
    private Long batchId;
    @NotNull
    private Integer quantity;
}
