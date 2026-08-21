package com.pharmacy.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ReturnItemRequest {
    @NotNull
    private Long saleItemId;
    @NotNull
    private Integer quantity;
}
