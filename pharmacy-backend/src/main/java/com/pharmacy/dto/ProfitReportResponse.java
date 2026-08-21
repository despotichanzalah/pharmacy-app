package com.pharmacy.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import java.math.BigDecimal;

@Data
@AllArgsConstructor
public class ProfitReportResponse {
    private String month;
    private BigDecimal totalSales;
    private BigDecimal totalCost;
    private BigDecimal totalRefunds;
    private BigDecimal netProfit;
}
