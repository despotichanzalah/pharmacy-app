package com.pharmacy.dto;

import lombok.Data;
import java.util.List;

@Data
public class SaleRequest {
    private String customerName;
    private List<SaleItemRequest> items;
}
