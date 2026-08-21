package com.pharmacy.service;

import com.pharmacy.dto.ReturnItemRequest;
import com.pharmacy.dto.ReturnRequest;
import com.pharmacy.exception.ResourceNotFoundException;
import com.pharmacy.model.*;
import com.pharmacy.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Service
@RequiredArgsConstructor
public class ReturnService {

    private final ReturnRepository returnRepository;
    private final ReturnItemRepository returnItemRepository;
    private final SaleRepository saleRepository;
    private final SaleItemRepository saleItemRepository;

    @Transactional
    public Return createReturn(ReturnRequest req, User staff) {
        Sale sale = saleRepository.findById(req.getSaleId())
                .orElseThrow(() -> new ResourceNotFoundException("Sale not found"));

        if (!sale.getShop().getId().equals(staff.getShop().getId())) {
            throw new IllegalArgumentException("Sale does not belong to your shop");
        }

        Return returnEntity = new Return();
        returnEntity.setSale(sale);
        returnEntity.setUser(staff);
        returnEntity.setShop(staff.getShop());
        returnEntity.setReason(req.getReason());
        returnEntity.setRefundAmount(BigDecimal.ZERO);
        returnEntity = returnRepository.save(returnEntity);

        BigDecimal refund = BigDecimal.ZERO;

        for (ReturnItemRequest itemReq : req.getItems()) {
            SaleItem saleItem = saleItemRepository.findById(itemReq.getSaleItemId())
                    .orElseThrow(() -> new ResourceNotFoundException("Sale item not found"));

            if (itemReq.getQuantity() > saleItem.getQuantity()) {
                throw new IllegalArgumentException("Return quantity exceeds sold quantity for item " + saleItem.getId());
            }

            // Restock the batch
            Batch batch = saleItem.getBatch();
            batch.setQuantity(batch.getQuantity() + itemReq.getQuantity());

            ReturnItem returnItem = new ReturnItem();
            returnItem.setReturnRef(returnEntity);
            returnItem.setSaleItem(saleItem);
            returnItem.setQuantity(itemReq.getQuantity());
            returnItemRepository.save(returnItem);

            refund = refund.add(saleItem.getPrice().multiply(BigDecimal.valueOf(itemReq.getQuantity())));
        }

        returnEntity.setRefundAmount(refund);
        return returnRepository.save(returnEntity);
    }
}
