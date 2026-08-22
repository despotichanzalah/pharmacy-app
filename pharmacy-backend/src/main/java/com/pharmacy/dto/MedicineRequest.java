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
    private Integer packSize; // e.g. 10 if this medicine is sold in strips of 10 tablets

    private List<Long> genericIds;     // existing generics picked from the list
    private List<String> newGenerics;  // typed-in generics not yet in the list — created on the fly
}
