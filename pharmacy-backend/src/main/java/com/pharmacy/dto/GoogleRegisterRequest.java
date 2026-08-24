package com.pharmacy.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class GoogleRegisterRequest {
    @NotBlank
    private String idToken;

    @NotBlank
    private String roleName;

    private String shopName; // set to create a NEW shop
    private Long shopId;     // set to JOIN an EXISTING shop
}
