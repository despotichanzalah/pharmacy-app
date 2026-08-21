package com.pharmacy.service;

import com.pharmacy.dto.*;
import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.Role;
import com.pharmacy.model.Shop;
import com.pharmacy.model.User;
import com.pharmacy.repository.RoleRepository;
import com.pharmacy.repository.ShopRepository;
import com.pharmacy.repository.UserRepository;
import com.pharmacy.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final ShopRepository shopRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtUtil jwtUtil;

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email already registered");
        }

        Shop shop;
        Role role;

        if (request.getShopId() != null) {
            // Joining an existing shop
            shop = shopRepository.findById(request.getShopId())
                    .orElseThrow(() -> new ResourceNotFoundException("Shop not found"));
            role = roleRepository.findByName(request.getRoleName())
                    .orElseThrow(() -> new ResourceNotFoundException("Role not found: " + request.getRoleName()));

        } else if (request.getShopName() != null && !request.getShopName().isBlank()) {
            // Creating a new shop — this user becomes its ADMIN
            shop = new Shop();
            shop.setName(request.getShopName());
            shop = shopRepository.save(shop);
            role = roleRepository.findByName("ADMIN")
                    .orElseThrow(() -> new ResourceNotFoundException("ADMIN role not found — seed roles first"));

        } else {
            throw new IllegalArgumentException("Provide either shopName (to create a shop) or shopId (to join one)");
        }

        User user = new User();
        user.setName(request.getName());
        user.setEmail(request.getEmail());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setRole(role);
        user.setShop(shop);
        userRepository.save(user);

        String token = jwtUtil.generateToken(user.getEmail(), role.getName());
        return new AuthResponse(token, user.getName(), user.getEmail(), role.getName(), shop.getId(), shop.getName());
    }

    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        String token = jwtUtil.generateToken(user.getEmail(), user.getRole().getName());
        return new AuthResponse(token, user.getName(), user.getEmail(), user.getRole().getName(),
                user.getShop().getId(), user.getShop().getName());
    }
}
