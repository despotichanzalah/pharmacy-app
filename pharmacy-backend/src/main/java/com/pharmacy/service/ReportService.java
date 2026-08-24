package com.pharmacy.service;

import java.time.LocalDate;
import com.pharmacy.dto.DailySalesResponse;
import com.pharmacy.dto.ProfitReportResponse;
import com.pharmacy.dto.TopMedicineResponse;
import com.pharmacy.model.Return;
import com.pharmacy.model.Sale;
import com.pharmacy.model.SaleItem;
import com.pharmacy.model.User;
import com.pharmacy.repository.ReturnRepository;
import com.pharmacy.repository.SaleItemRepository;
import com.pharmacy.repository.SaleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
@RequiredArgsConstructor
public class ReportService {

    private final SaleRepository saleRepository;
    private final SaleItemRepository saleItemRepository;
    private final ReturnRepository returnRepository;

    public ProfitReportResponse monthlyProfit(YearMonth month, User currentUser) {
        Long shopId = currentUser.getShop().getId();
        LocalDateTime start = month.atDay(1).atStartOfDay();
        LocalDateTime end = month.atEndOfMonth().atTime(23, 59, 59);

        List<Sale> sales = saleRepository.findByShopIdAndSaleDateBetween(shopId, start, end);

        BigDecimal totalSales = BigDecimal.ZERO;
        BigDecimal totalCost = BigDecimal.ZERO;

        for (Sale sale : sales) {
            totalSales = totalSales.add(sale.getTotalAmount());

            List<SaleItem> items = saleItemRepository.findBySaleId(sale.getId());
            for (SaleItem item : items) {
                BigDecimal cost = item.getBatch().getPurchasePrice().multiply(BigDecimal.valueOf(item.getQuantity()));
                totalCost = totalCost.add(cost);
            }
        }

        // Refunds issued during the same window (same shop) reduce net profit.
        BigDecimal totalRefunds = returnRepository.findAll().stream()
                .filter(r -> r.getShop().getId().equals(shopId))
                .filter(r -> !r.getReturnDate().isBefore(start) && !r.getReturnDate().isAfter(end))
                .map(Return::getRefundAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal netProfit = totalSales.subtract(totalCost).subtract(totalRefunds);

        return new ProfitReportResponse(
                month.format(DateTimeFormatter.ofPattern("MMMM yyyy")),
                totalSales, totalCost, totalRefunds, netProfit
        );
    }

    // Ranks medicines by units sold in the given month — used for the "top sellers" dashboard panel.
    public List<TopMedicineResponse> topMedicines(YearMonth month, User currentUser, int limit) {        Long shopId = currentUser.getShop().getId();
        LocalDateTime start = month.atDay(1).atStartOfDay();
        LocalDateTime end = month.atEndOfMonth().atTime(23, 59, 59);

        List<Sale> sales = saleRepository.findByShopIdAndSaleDateBetween(shopId, start, end);

        Map<String, Integer> quantityByMedicine = new HashMap<>();
        for (Sale sale : sales) {
            for (SaleItem item : saleItemRepository.findBySaleId(sale.getId())) {
                String medicineName = item.getBatch().getMedicine().getName();
                quantityByMedicine.merge(medicineName, item.getQuantity(), Integer::sum);
            }
        }

        return quantityByMedicine.entrySet().stream()
                .sorted((a, b) -> b.getValue() - a.getValue())
                .limit(limit)
                .map(e -> new TopMedicineResponse(e.getKey(), e.getValue()))
                .toList();
    }

    // Sums sales for each of the last `days` days — used for the "Revenue trend" dashboard chart.
    public List<DailySalesResponse> dailySales(int days, User currentUser) {
        Long shopId = currentUser.getShop().getId();
        LocalDateTime start = LocalDateTime.now().minusDays(days - 1).toLocalDate().atStartOfDay();
        LocalDateTime end = LocalDateTime.now();

        List<Sale> sales = saleRepository.findByShopIdAndSaleDateBetween(shopId, start, end);

        Map<LocalDate, BigDecimal> totalByDay = new LinkedHashMap<>();
        for (int i = days - 1; i >= 0; i--) {
            totalByDay.put(LocalDate.now().minusDays(i), BigDecimal.ZERO);
        }
        for (Sale sale : sales) {
            LocalDate day = sale.getSaleDate().toLocalDate();
            totalByDay.merge(day, sale.getTotalAmount(), BigDecimal::add);
        }

        return totalByDay.entrySet().stream()
                .map(e -> new DailySalesResponse(e.getKey().toString(), e.getValue()))
                .toList();
    }
}
