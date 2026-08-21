package com.pharmacy.controller;

import com.pharmacy.dto.SaleRequest;
import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.Sale;
import com.pharmacy.model.SaleItem;
import com.pharmacy.model.User;
import com.pharmacy.repository.UserRepository;
import com.pharmacy.service.SalesService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/sales")
@RequiredArgsConstructor
public class SaleController {

    private final SalesService salesService;
    private final UserRepository userRepository;

    private User currentUser(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Authenticated user not found"));
    }

    @PostMapping
    public Sale createSale(@Valid @RequestBody SaleRequest request, Authentication auth) {
        return salesService.createSale(request, currentUser(auth));
    }

    @GetMapping
    public List<Sale> listSales(Authentication auth) {
        return salesService.listSales(currentUser(auth));
    }

    @GetMapping("/{id}/items")
    public List<SaleItem> saleItems(@PathVariable Long id) {
        return salesService.saleItems(id);
    }
}
