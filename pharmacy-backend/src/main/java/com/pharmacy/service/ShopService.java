package com.pharmacy.service;

import com.pharmacy.model.*;
import com.pharmacy.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ShopService {

    private final ShopRepository shopRepository;
    private final UserRepository userRepository;
    private final ReturnRepository returnRepository;
    private final ReturnItemRepository returnItemRepository;
    private final SaleRepository saleRepository;
    private final SaleItemRepository saleItemRepository;
    private final PurchaseRepository purchaseRepository;
    private final PurchaseItemRepository purchaseItemRepository;
    private final BatchRepository batchRepository;
    private final MedicineRepository medicineRepository;
    private final SupplierRepository supplierRepository;
    private final CategoryRepository categoryRepository;

    // Permanently deletes the caller's shop and everything in it. Order matters —
    // each step clears the rows that would otherwise block the next delete via a foreign key.
    @Transactional
    public void deleteMyShop(User currentUser) {
        Long shopId = currentUser.getShop().getId();

        for (Return r : returnRepository.findByShopId(shopId)) {
            returnItemRepository.deleteAll(returnItemRepository.findByReturnRefId(r.getId()));
            returnRepository.delete(r);
        }

        for (Sale s : saleRepository.findByShopId(shopId)) {
            saleItemRepository.deleteAll(saleItemRepository.findBySaleId(s.getId()));
            saleRepository.delete(s);
        }

        for (Purchase p : purchaseRepository.findByShopId(shopId)) {
            purchaseItemRepository.deleteAll(purchaseItemRepository.findByPurchaseId(p.getId()));
            purchaseRepository.delete(p);
        }

        batchRepository.deleteAll(batchRepository.findByShopId(shopId));

        for (Medicine m : medicineRepository.findByShopId(shopId)) {
            m.getGenerics().clear();
            medicineRepository.save(m);
            medicineRepository.delete(m);
        }

        supplierRepository.deleteAll(supplierRepository.findByShopId(shopId));
        categoryRepository.deleteAll(categoryRepository.findByShopId(shopId));
        userRepository.deleteAll(userRepository.findByShopId(shopId));

        shopRepository.deleteById(shopId);
    }
}
