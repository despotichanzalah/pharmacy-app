package com.pharmacy.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

@Data
public class SaleRequest {
    private String customerName;
    private BigDecimal discountPercent;
    private List<SaleItemRequest> items;
}
