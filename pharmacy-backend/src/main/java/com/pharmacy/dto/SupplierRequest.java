package com.pharmacy.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SupplierRequest {
    @NotBlank
    private String name;
    private String contact;
    private String address;
}
