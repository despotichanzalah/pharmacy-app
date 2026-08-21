package com.pharmacy.controller;

import com.pharmacy.dto.ReturnRequest;
import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.Return;
import com.pharmacy.model.User;
import com.pharmacy.repository.UserRepository;
import com.pharmacy.service.ReturnService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/returns")
@RequiredArgsConstructor
public class ReturnController {

    private final ReturnService returnService;
    private final UserRepository userRepository;

    @PostMapping
    public Return createReturn(@Valid @RequestBody ReturnRequest request, Authentication auth) {
        User staff = userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Authenticated user not found"));
        return returnService.createReturn(request, staff);
    }
}
