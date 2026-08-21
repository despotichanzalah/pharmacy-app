package com.pharmacy.repository;

import com.pharmacy.model.ReturnItem;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ReturnItemRepository extends JpaRepository<ReturnItem, Long> {
    List<ReturnItem> findByReturnRefId(Long returnId);
}
