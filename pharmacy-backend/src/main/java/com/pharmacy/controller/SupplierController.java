package com.pharmacy.controller;

import com.pharmacy.dto.SupplierRequest;
import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.Supplier;
import com.pharmacy.model.User;
import com.pharmacy.repository.UserRepository;
import com.pharmacy.service.SupplierService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/suppliers")
@RequiredArgsConstructor
public class SupplierController {

    private final SupplierService supplierService;
    private final UserRepository userRepository;

    private User currentUser(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Authenticated user not found"));
    }

    @PostMapping
    public Supplier addSupplier(@Valid @RequestBody SupplierRequest request, Authentication auth) {
        return supplierService.addSupplier(request, currentUser(auth));
    }

    @GetMapping
    public List<Supplier> listSuppliers(Authentication auth) {
        return supplierService.listSuppliers(currentUser(auth));
    }
}
