package com.pharmacy.controller;

import com.pharmacy.dto.GenericRequest;
import com.pharmacy.model.Generic;
import com.pharmacy.repository.GenericRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/generics")
@RequiredArgsConstructor
public class GenericController {

    private final GenericRepository genericRepository;

    // Shared across all shops — every pharmacy searches the same master list.
    @GetMapping
    public List<Generic> listGenerics(@RequestParam(required = false) String query) {
        return (query == null || query.isBlank())
                ? genericRepository.findAll()
                : genericRepository.findByNameContainingIgnoreCase(query);
    }

    @PostMapping
    public Generic addGeneric(@Valid @RequestBody GenericRequest request) {
        return genericRepository.findByNameIgnoreCase(request.getName().trim())
                .orElseGet(() -> genericRepository.save(new Generic(null, request.getName().trim())));
    }
}
