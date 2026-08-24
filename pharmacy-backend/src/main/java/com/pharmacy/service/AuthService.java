package com.pharmacy.service;

import com.pharmacy.dto.*;
import com.pharmacy.exception.GoogleAccountNotRegisteredException;
import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.Role;
import com.pharmacy.model.Shop;
import com.pharmacy.model.User;
import com.pharmacy.repository.RoleRepository;
import com.pharmacy.repository.ShopRepository;
import com.pharmacy.repository.UserRepository;
import com.pharmacy.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {

    private static final long REMEMBER_ME_EXPIRATION_MS = 30L * 24 * 60 * 60 * 1000; // 30 days

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final ShopRepository shopRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtUtil jwtUtil;
    private final EmailService emailService;
    private final GoogleAuthService googleAuthService;

    @Value("${jwt.expiration-ms}")
    private long defaultExpirationMs;

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email already registered");
        }

        Shop shop;
        Role role;

        if (request.getShopId() != null) {
            shop = shopRepository.findById(request.getShopId())
                    .orElseThrow(() -> new ResourceNotFoundException("Shop not found"));
            role = roleRepository.findByName(request.getRoleName())
                    .orElseThrow(() -> new ResourceNotFoundException("Role not found: " + request.getRoleName()));

        } else if (request.getShopName() != null && !request.getShopName().isBlank()) {
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

        long expiry = request.isRememberMe() ? REMEMBER_ME_EXPIRATION_MS : defaultExpirationMs;
        String token = jwtUtil.generateToken(user.getEmail(), user.getRole().getName(), expiry);

        notifyAdminsOfLogin(user);

        return new AuthResponse(token, user.getName(), user.getEmail(), user.getRole().getName(),
                user.getShop().getId(), user.getShop().getName());
    }

    public void forgotPassword(ForgotPasswordRequest request) {
        userRepository.findByEmail(request.getEmail()).ifPresent(user -> {
            String token = UUID.randomUUID().toString();
            user.setResetToken(token);
            user.setResetTokenExpiry(LocalDateTime.now().plusHours(1));
            userRepository.save(user);
            emailService.sendPasswordResetEmail(user.getEmail(), token);
        });
    }

    public void resetPassword(ResetPasswordRequest request) {
        User user = userRepository.findByResetToken(request.getToken())
                .orElseThrow(() -> new IllegalArgumentException("This reset link is invalid or has already been used."));

        if (user.getResetTokenExpiry() == null || user.getResetTokenExpiry().isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException("This reset link has expired. Please request a new one.");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        user.setResetToken(null);
        user.setResetTokenExpiry(null);
        userRepository.save(user);
    }

    // --- Google sign-in ---

    public AuthResponse googleLogin(String idToken) {
        Map<String, Object> info = googleAuthService.verify(idToken);
        String email = (String) info.get("email");

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new GoogleAccountNotRegisteredException(email, (String) info.get("name")));

        String token = jwtUtil.generateToken(user.getEmail(), user.getRole().getName(), REMEMBER_ME_EXPIRATION_MS);
        notifyAdminsOfLogin(user);

        return new AuthResponse(token, user.getName(), user.getEmail(), user.getRole().getName(),
                user.getShop().getId(), user.getShop().getName());
    }

    public AuthResponse googleRegister(GoogleRegisterRequest request) {
        Map<String, Object> info = googleAuthService.verify(request.getIdToken());
        String email = (String) info.get("email");
        String name = (String) info.get("name");

        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("This Google account is already registered — try signing in instead.");
        }

        Shop shop;
        Role role;

        if (request.getShopId() != null) {
            shop = shopRepository.findById(request.getShopId())
                    .orElseThrow(() -> new ResourceNotFoundException("Shop not found"));
            role = roleRepository.findByName(request.getRoleName())
                    .orElseThrow(() -> new ResourceNotFoundException("Role not found: " + request.getRoleName()));

        } else if (request.getShopName() != null && !request.getShopName().isBlank()) {
            shop = new Shop();
            shop.setName(request.getShopName());
            shop = shopRepository.save(shop);
            role = roleRepository.findByName("ADMIN")
                    .orElseThrow(() -> new ResourceNotFoundException("ADMIN role not found — seed roles first"));

        } else {
            throw new IllegalArgumentException("Provide either shopName (to create a shop) or shopId (to join one)");
        }

        User user = new User();
        user.setName(name != null ? name : email);
        user.setEmail(email);
        // Google-authenticated accounts never log in with a password — this random hash just
        // satisfies the database's not-null constraint.
        user.setPasswordHash(passwordEncoder.encode(UUID.randomUUID().toString()));
        user.setRole(role);
        user.setShop(shop);
        userRepository.save(user);

        String token = jwtUtil.generateToken(user.getEmail(), role.getName(), REMEMBER_ME_EXPIRATION_MS);
        return new AuthResponse(token, user.getName(), user.getEmail(), role.getName(), shop.getId(), shop.getName());
    }

    private void notifyAdminsOfLogin(User user) {
        if (!user.getRole().getName().equals("ADMIN")) {
            List<User> admins = userRepository.findByShopIdAndRole_Name(user.getShop().getId(), "ADMIN");
            for (User admin : admins) {
                emailService.sendLoginAlertEmail(admin.getEmail(), user.getName(), user.getEmail(), user.getRole().getName());
            }
        }
    }
}
