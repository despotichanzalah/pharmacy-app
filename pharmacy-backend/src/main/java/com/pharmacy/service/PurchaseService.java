package com.pharmacy.service;

import com.pharmacy.dto.PurchaseItemRequest;
import com.pharmacy.dto.PurchaseRequest;
import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.*;
import com.pharmacy.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PurchaseService {

    private final PurchaseRepository purchaseRepository;
    private final PurchaseItemRepository purchaseItemRepository;
    private final SupplierRepository supplierRepository;
    private final MedicineRepository medicineRepository;

    @Transactional
    public Purchase createPurchase(PurchaseRequest req, User currentUser) {
        Supplier supplier = supplierRepository.findById(req.getSupplierId())
                .orElseThrow(() -> new ResourceNotFoundException("Supplier not found"));

        if (!supplier.getShop().getId().equals(currentUser.getShop().getId())) {
            throw new IllegalArgumentException("Supplier does not belong to your shop");
        }

        Purchase purchase = new Purchase();
        purchase.setSupplier(supplier);
        purchase.setUser(currentUser);
        purchase.setShop(currentUser.getShop());
        purchase.setTotalAmount(BigDecimal.ZERO);
        purchase = purchaseRepository.save(purchase);

        BigDecimal total = BigDecimal.ZERO;

        for (PurchaseItemRequest itemReq : req.getItems()) {
            Medicine medicine = medicineRepository.findById(itemReq.getMedicineId())
                    .orElseThrow(() -> new ResourceNotFoundException("Medicine not found: " + itemReq.getMedicineId()));

            if (!medicine.getShop().getId().equals(currentUser.getShop().getId())) {
                throw new IllegalArgumentException("Medicine does not belong to your shop");
            }

            PurchaseItem item = new PurchaseItem();
            item.setPurchase(purchase);
            item.setMedicine(medicine);
            item.setBatchNumber(itemReq.getBatchNumber());
            item.setQuantity(itemReq.getQuantity());
            item.setUnitPrice(itemReq.getUnitPrice());
            item.setExpiryDate(itemReq.getExpiryDate());
            purchaseItemRepository.save(item);

            total = total.add(itemReq.getUnitPrice().multiply(BigDecimal.valueOf(itemReq.getQuantity())));
        }

        purchase.setTotalAmount(total);
        return purchaseRepository.save(purchase);
    }

    public List<Purchase> listPurchases(User currentUser) {
        return purchaseRepository.findByShopId(currentUser.getShop().getId());
    }

    public List<PurchaseItem> purchaseItems(Long purchaseId) {
        return purchaseItemRepository.findByPurchaseId(purchaseId);
    }
}
