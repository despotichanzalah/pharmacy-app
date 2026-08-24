package com.pharmacy.repository;

import com.pharmacy.model.Return;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ReturnRepository extends JpaRepository<Return, Long> {
    List<Return> findByShopId(Long shopId);
}
