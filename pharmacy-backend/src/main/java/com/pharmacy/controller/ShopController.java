package com.pharmacy.controller;

import com.pharmacy.model.Shop;
import com.pharmacy.repository.ShopRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/shops")
@RequiredArgsConstructor
public class ShopController {

    private final ShopRepository shopRepository;

    // Public — so a new staff member can pick which shop to join at registration.
    @GetMapping
    public List<Shop> listShops() {
        return shopRepository.findAll();
    }
}
