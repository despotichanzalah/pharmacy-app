package com.pharmacy.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.List;

@Data
public class ReturnRequest {
    @NotNull
    private Long saleId;
    private String reason;
    private List<ReturnItemRequest> items;
}
