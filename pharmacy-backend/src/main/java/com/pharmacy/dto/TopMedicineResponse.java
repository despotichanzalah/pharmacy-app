package com.pharmacy.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class TopMedicineResponse {
    private String medicineName;
    private int quantitySold;
}
