package com.pharmacy.controller;

import com.pharmacy.dto.PurchaseRequest;
import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.Purchase;
import com.pharmacy.model.PurchaseItem;
import com.pharmacy.model.User;
import com.pharmacy.repository.UserRepository;
import com.pharmacy.service.PurchaseService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/purchases")
@RequiredArgsConstructor
public class PurchaseController {

    private final PurchaseService purchaseService;
    private final UserRepository userRepository;

    private User currentUser(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Authenticated user not found"));
    }

    @PostMapping
    public Purchase createPurchase(@Valid @RequestBody PurchaseRequest request, Authentication auth) {
        return purchaseService.createPurchase(request, currentUser(auth));
    }

    @GetMapping
    public List<Purchase> listPurchases(Authentication auth) {
        return purchaseService.listPurchases(currentUser(auth));
    }

    @GetMapping("/{id}/items")
    public List<PurchaseItem> purchaseItems(@PathVariable Long id) {
        return purchaseService.purchaseItems(id);
    }
}
