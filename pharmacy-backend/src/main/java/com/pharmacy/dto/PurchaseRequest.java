package com.pharmacy.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.List;

@Data
public class PurchaseRequest {
    @NotNull
    private Long supplierId;
    private List<PurchaseItemRequest> items;
}
