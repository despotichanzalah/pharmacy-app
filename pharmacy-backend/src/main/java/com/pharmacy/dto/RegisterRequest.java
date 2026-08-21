package com.pharmacy.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RegisterRequest {
    @NotBlank
    private String name;

    @NotBlank @Email
    private String email;

    @NotBlank
    private String password;

    @NotBlank
    private String roleName; // ADMIN, PHARMACIST, CASHIER

    // Provide ONE of these:
    private String shopName;  // set this to create a NEW shop (you become its ADMIN)
    private Long shopId;      // set this to JOIN an EXISTING shop
}
