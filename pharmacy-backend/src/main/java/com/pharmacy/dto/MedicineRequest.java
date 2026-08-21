package com.pharmacy.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import java.util.List;

@Data
public class MedicineRequest {
    @NotBlank
    private String name;
    private Long categoryId;
    private String unit;
    private Integer reorderLevel;

    private List<Long> genericIds;     // existing generics picked from the list
    private List<String> newGenerics;  // typed-in generics not yet in the list — created on the fly
}
