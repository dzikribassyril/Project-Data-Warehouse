-- ==============================================================================
-- File      : 07_check_etl_result.sql
-- Tujuan    : Quality Assurance (QA) dan Validasi Hasil Akhir Data Warehouse
-- ==============================================================================

USE Logistics_DW;
GO

-- 1. CEK JUMLAH BARIS SELURUH TABEL
SELECT 'DimDate' AS TableName, COUNT(*) AS TotalRows FROM DimDate
UNION ALL SELECT 'DimCustomer', COUNT(*) FROM DimCustomer
UNION ALL SELECT 'DimBranch', COUNT(*) FROM DimBranch
UNION ALL SELECT 'DimCourier', COUNT(*) FROM DimCourier
UNION ALL SELECT 'DimService', COUNT(*) FROM DimService
UNION ALL SELECT 'DimPackage', COUNT(*) FROM DimPackage
UNION ALL SELECT 'DimShipmentStatus', COUNT(*) FROM DimShipmentStatus
UNION ALL SELECT 'DimRoute', COUNT(*) FROM DimRoute
UNION ALL SELECT 'DimPayment', COUNT(*) FROM DimPayment
UNION ALL SELECT 'FactDeliveryPerformance', COUNT(*) FROM FactDeliveryPerformance;
GO

-- 2. VALIDASI DISTRIBUSI STATUS PENGIRIMAN
SELECT 
    dss.status_name,
    COUNT(f.shipment_key) AS Total_Pengiriman,
    CAST(COUNT(f.shipment_key) * 100.0 / (SELECT COUNT(*) FROM FactDeliveryPerformance) AS DECIMAL(5,2)) AS Persentase
FROM FactDeliveryPerformance f
JOIN DimShipmentStatus dss ON f.status_key = dss.status_key
GROUP BY dss.status_name
ORDER BY Total_Pengiriman DESC;
GO

-- 3. CEK KUALITAS DATA (ANOMALY DETECTION)
SELECT 
    SUM(CASE WHEN delay_days < 0 THEN 1 ELSE 0 END) AS Error_Negative_Delay,
    SUM(CASE WHEN total_amount < 0 THEN 1 ELSE 0 END) AS Error_Negative_Amount,
    SUM(CASE WHEN is_delivered = 1 AND actual_days IS NULL THEN 1 ELSE 0 END) AS Error_Delivered_No_ActualDays,
    SUM(CASE WHEN transaction_date_key IS NULL THEN 1 ELSE 0 END) AS Error_Missing_Date
FROM FactDeliveryPerformance;
GO

-- 4. PREVIEW KPI
SELECT 
    SUM(total_shipment) AS Total_Shipments,
    SUM(total_amount) AS Total_Revenue,
    CAST(SUM(CAST(is_delivered AS INT)) * 100.0 / SUM(total_shipment) AS DECIMAL(5,2)) AS Delivery_Rate_Pct,
    CAST((SUM(total_shipment) - SUM(CAST(is_late AS INT))) * 100.0 / NULLIF(SUM(CAST(is_delivered AS INT)), 0) AS DECIMAL(5,2)) AS On_Time_Rate_Pct,
    AVG(CAST(delay_days AS DECIMAL(5,2))) AS Avg_Delay_Days
FROM FactDeliveryPerformance;
GO