package com.pharmacy.repository;

import com.pharmacy.model.Generic;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface GenericRepository extends JpaRepository<Generic, Long> {
    Optional<Generic> findByNameIgnoreCase(String name);
    List<Generic> findByNameContainingIgnoreCase(String query);
}
