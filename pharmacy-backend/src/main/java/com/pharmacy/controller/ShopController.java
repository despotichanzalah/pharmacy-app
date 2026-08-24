package com.pharmacy.controller;

import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.Shop;
import com.pharmacy.model.User;
import com.pharmacy.repository.ShopRepository;
import com.pharmacy.repository.UserRepository;
import com.pharmacy.service.ShopService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/shops")
@RequiredArgsConstructor
public class ShopController {

    private final ShopRepository shopRepository;
    private final ShopService shopService;
    private final UserRepository userRepository;

    // Public — so a new staff member can pick which shop to join at registration.
    @GetMapping
    public List<Shop> listShops() {
        return shopRepository.findAll();
    }

    // Permanently closes the caller's own shop and deletes everything in it.
    @DeleteMapping("/mine")
    public void deleteMyShop(Authentication auth) {
        User currentUser = userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Authenticated user not found"));
        shopService.deleteMyShop(currentUser);
    }
}
