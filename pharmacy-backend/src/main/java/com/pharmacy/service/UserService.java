package com.pharmacy.service;

import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.User;
import com.pharmacy.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    public List<User> listStaff(User currentUser) {
        return userRepository.findByShopId(currentUser.getShop().getId());
    }

    public void deleteUser(Long userId, User currentUser) {
        User target = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (!target.getShop().getId().equals(currentUser.getShop().getId())) {
            throw new IllegalArgumentException("That account does not belong to your shop");
        }

        if (target.getId().equals(currentUser.getId())) {
            throw new IllegalArgumentException("You can't remove your own account this way — delete the whole shop instead if you're closing it.");
        }

        // If this staff member has sales, purchases, or returns on record, the delete will
        // hit a foreign-key conflict and the global handler returns a friendly message for it.
        userRepository.delete(target);
    }

    public void approveUser(Long userId, User currentUser) {
        User target = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (!target.getShop().getId().equals(currentUser.getShop().getId())) {
            throw new IllegalArgumentException("That account does not belong to your shop");
        }

        target.setApproved(true);
        userRepository.save(target);
    }
}
