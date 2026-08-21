package com.pharmacy.service;

import com.pharmacy.dto.SaleItemRequest;
import com.pharmacy.dto.SaleRequest;
import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.*;
import com.pharmacy.repository.BatchRepository;
import com.pharmacy.repository.SaleItemRepository;
import com.pharmacy.repository.SaleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Service
@RequiredArgsConstructor
public class SalesService {

    private final SaleRepository saleRepository;
    private final SaleItemRepository saleItemRepository;
    private final BatchRepository batchRepository;

    @Transactional
    public Sale createSale(SaleRequest req, User cashier) {        Sale sale = new Sale();
        sale.setUser(cashier);
        sale.setShop(cashier.getShop());
        sale.setCustomerName(req.getCustomerName());
        sale.setTotalAmount(BigDecimal.ZERO);
        sale = saleRepository.save(sale);

        BigDecimal total = BigDecimal.ZERO;

        for (SaleItemRequest itemReq : req.getItems()) {
            Batch batch = batchRepository.findById(itemReq.getBatchId())
                    .orElseThrow(() -> new ResourceNotFoundException("Batch not found: " + itemReq.getBatchId()));

            if (!batch.getShop().getId().equals(cashier.getShop().getId())) {
                throw new IllegalArgumentException("Batch does not belong to your shop");
            }

            if (batch.getQuantity() < itemReq.getQuantity()) {
                throw new IllegalArgumentException("Insufficient stock for batch " + batch.getBatchNumber());
            }

            batch.setQuantity(batch.getQuantity() - itemReq.getQuantity());
            batchRepository.save(batch);

            SaleItem saleItem = new SaleItem();
            saleItem.setSale(sale);
            saleItem.setBatch(batch);
            saleItem.setQuantity(itemReq.getQuantity());
            saleItem.setPrice(batch.getSalePrice());
            saleItemRepository.save(saleItem);

            total = total.add(batch.getSalePrice().multiply(BigDecimal.valueOf(itemReq.getQuantity())));
        }

        sale.setTotalAmount(total);
        return saleRepository.save(sale);
    }

    public java.util.List<Sale> listSales(User currentUser) {
        return saleRepository.findByShopIdOrderBySaleDateDesc(currentUser.getShop().getId());
    }

    public java.util.List<SaleItem> saleItems(Long saleId) {
        return saleItemRepository.findBySaleId(saleId);
    }
}
