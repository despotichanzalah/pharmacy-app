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
import java.math.RoundingMode;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SalesService {

    private static final BigDecimal HUNDRED = new BigDecimal("100");

    private final SaleRepository saleRepository;
    private final SaleItemRepository saleItemRepository;
    private final BatchRepository batchRepository;

    @Transactional
    public Sale createSale(SaleRequest req, User cashier) {
        BigDecimal discountPercent = normalizeDiscount(req.getDiscountPercent());

        Sale sale = new Sale();
        sale.setUser(cashier);
        sale.setShop(cashier.getShop());
        sale.setCustomerName(req.getCustomerName());
        sale.setDiscountPercent(discountPercent);
        sale.setSubtotalAmount(BigDecimal.ZERO);
        sale.setTotalAmount(BigDecimal.ZERO);
        sale = saleRepository.save(sale);

        BigDecimal subtotal = BigDecimal.ZERO;

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

            subtotal = subtotal.add(batch.getSalePrice().multiply(BigDecimal.valueOf(itemReq.getQuantity())));
        }

        subtotal = subtotal.setScale(2, RoundingMode.HALF_UP);
        BigDecimal total = applyDiscount(subtotal, discountPercent);

        sale.setSubtotalAmount(subtotal);
        sale.setDiscountPercent(discountPercent);
        sale.setTotalAmount(total);
        return saleRepository.save(sale);
    }

    public List<Sale> listSales(User currentUser) {
        return saleRepository.findByShopIdOrderBySaleDateDesc(currentUser.getShop().getId());
    }

    public List<SaleItem> saleItems(Long saleId) {
        return saleItemRepository.findBySaleId(saleId);
    }

    static BigDecimal normalizeDiscount(BigDecimal discountPercent) {
        BigDecimal value = discountPercent == null ? BigDecimal.ZERO : discountPercent;
        if (value.compareTo(BigDecimal.ZERO) < 0 || value.compareTo(HUNDRED) > 0) {
            throw new IllegalArgumentException("Discount must be between 0 and 100 percent");
        }
        return value.setScale(2, RoundingMode.HALF_UP);
    }

    static BigDecimal applyDiscount(BigDecimal amount, BigDecimal discountPercent) {
        BigDecimal percent = discountPercent == null ? BigDecimal.ZERO : discountPercent;
        if (percent.compareTo(BigDecimal.ZERO) <= 0) {
            return amount.setScale(2, RoundingMode.HALF_UP);
        }
        return amount.multiply(HUNDRED.subtract(percent))
                .divide(HUNDRED, 2, RoundingMode.HALF_UP);
    }
}
