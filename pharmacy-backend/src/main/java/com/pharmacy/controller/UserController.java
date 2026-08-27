package com.pharmacy.controller;

import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.User;
import com.pharmacy.repository.UserRepository;
import com.pharmacy.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final UserRepository userRepository;

    private User currentUser(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Authenticated user not found"));
    }

    // List everyone on the caller's shop staff.
    @GetMapping
    public List<User> listStaff(Authentication auth) {
        return userService.listStaff(currentUser(auth));
    }

    // Remove a staff member who has left the shop. Can't be used to delete your own account.
    @DeleteMapping("/{id}")
    public void deleteUser(@PathVariable Long id, Authentication auth) {
        userService.deleteUser(id, currentUser(auth));
    }

    // Approves a staff member who joined this shop and is waiting for access.
    @PutMapping("/{id}/approve")
    public void approveUser(@PathVariable Long id, Authentication auth) {
        userService.approveUser(id, currentUser(auth));
    }
}
