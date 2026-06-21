-- ==============================================================================
-- File      : 07_check_etl_result.sql
-- Tujuan    : Quality Assurance (QA) & Validasi Hasil Akhir Data Warehouse
-- Jalankan  : Setelah 06_transform_and_load_fact.sql
-- ==============================================================================

USE Logistics_DW;
GO

-- ============================================================
-- 1. ROW COUNT SEMUA TABEL
-- ============================================================
PRINT '=== [1] ROW COUNT ===';
SELECT TableName, TotalRows FROM (
    SELECT 'DimDate'                  AS TableName, COUNT(*) AS TotalRows FROM dw.DimDate            UNION ALL
    SELECT 'DimCustomer',                           COUNT(*)              FROM dw.DimCustomer         UNION ALL
    SELECT 'DimBranch',                             COUNT(*)              FROM dw.DimBranch           UNION ALL
    SELECT 'DimCourier',                            COUNT(*)              FROM dw.DimCourier          UNION ALL
    SELECT 'DimService',                            COUNT(*)              FROM dw.DimService          UNION ALL
    SELECT 'DimPackage',                            COUNT(*)              FROM dw.DimPackage          UNION ALL
    SELECT 'DimShipmentStatus',                     COUNT(*)              FROM dw.DimShipmentStatus   UNION ALL
    SELECT 'DimRoute',                              COUNT(*)              FROM dw.DimRoute            UNION ALL
    SELECT 'DimPayment',                            COUNT(*)              FROM dw.DimPayment          UNION ALL
    SELECT 'FactDeliveryPerformance',               COUNT(*)              FROM dw.FactDeliveryPerformance
) t
ORDER BY CASE WHEN TableName = 'FactDeliveryPerformance' THEN 1 ELSE 0 END, TableName;
GO

-- ============================================================
-- 2. DISTRIBUSI STATUS PENGIRIMAN
-- ============================================================
PRINT '=== [2] DISTRIBUSI STATUS ===';
SELECT
    dss.status_name                 AS Status,
    dss.status_category             AS Kategori,
    COUNT(f.shipment_key)           AS Total_Pengiriman,
    CAST(
        COUNT(f.shipment_key) * 100.0
        / SUM(COUNT(f.shipment_key)) OVER()
    AS DECIMAL(5,2))                AS Persentase_Pct
FROM dw.FactDeliveryPerformance f
JOIN dw.DimShipmentStatus dss ON f.status_key = dss.status_key
GROUP BY dss.status_name, dss.status_category
ORDER BY Total_Pengiriman DESC;
GO

-- ============================================================
-- 3. DATA QUALITY CHECK — ANOMALY DETECTION
-- ============================================================
PRINT '=== [3] DATA QUALITY CHECK ===';
SELECT
    SUM(CASE WHEN delay_days < 0                                THEN 1 ELSE 0 END) AS Error_Negative_Delay,
    SUM(CASE WHEN total_amount < 0                              THEN 1 ELSE 0 END) AS Error_Negative_Amount,
    SUM(CASE WHEN shipping_fee <= 0                             THEN 1 ELSE 0 END) AS Error_Zero_ShippingFee,
    SUM(CASE WHEN is_delivered = 1 AND actual_days IS NULL      THEN 1 ELSE 0 END) AS Error_Delivered_NoActualDays,
    SUM(CASE WHEN is_delivered = 1 AND delivery_date_key IS NULL THEN 1 ELSE 0 END) AS Error_Delivered_NoDeliveryDate,
    SUM(CASE WHEN is_delivered = 0 AND actual_days IS NOT NULL  THEN 1 ELSE 0 END) AS Warning_NonDelivered_HasActualDays,
    SUM(CASE WHEN transaction_date_key IS NULL                  THEN 1 ELSE 0 END) AS Error_Missing_TransactionDate,
    SUM(CASE WHEN CAST(is_delivered AS INT) + CAST(is_failed AS INT) + CAST(is_returned AS INT) + CAST(is_cancelled AS INT) > 1
                                                                THEN 1 ELSE 0 END) AS Error_MultipleFlags
FROM dw.FactDeliveryPerformance;
GO

-- ============================================================
-- 4. REFERENTIAL INTEGRITY CHECK (Orphan FK)
-- ============================================================
PRINT '=== [4] REFERENTIAL INTEGRITY CHECK ===';
SELECT
    SUM(CASE WHEN dd.date_key    IS NULL THEN 1 ELSE 0 END) AS Orphan_TransactionDate,
    SUM(CASE WHEN dc.customer_key IS NULL THEN 1 ELSE 0 END) AS Orphan_Customer,
    SUM(CASE WHEN db.branch_key  IS NULL THEN 1 ELSE 0 END) AS Orphan_Branch,
    SUM(CASE WHEN dco.courier_key IS NULL THEN 1 ELSE 0 END) AS Orphan_Courier,
    SUM(CASE WHEN ds.service_key IS NULL THEN 1 ELSE 0 END) AS Orphan_Service,
    SUM(CASE WHEN dp.package_key IS NULL THEN 1 ELSE 0 END) AS Orphan_Package,
    SUM(CASE WHEN dss.status_key IS NULL THEN 1 ELSE 0 END) AS Orphan_Status,
    SUM(CASE WHEN dr.route_key   IS NULL THEN 1 ELSE 0 END) AS Orphan_Route,
    SUM(CASE WHEN dpy.payment_key IS NULL THEN 1 ELSE 0 END) AS Orphan_Payment
FROM dw.FactDeliveryPerformance f
LEFT JOIN dw.DimDate            dd  ON f.transaction_date_key = dd.date_key
LEFT JOIN dw.DimCustomer        dc  ON f.customer_key         = dc.customer_key
LEFT JOIN dw.DimBranch          db  ON f.branch_key           = db.branch_key
LEFT JOIN dw.DimCourier         dco ON f.courier_key          = dco.courier_key
LEFT JOIN dw.DimService         ds  ON f.service_key          = ds.service_key
LEFT JOIN dw.DimPackage         dp  ON f.package_key          = dp.package_key
LEFT JOIN dw.DimShipmentStatus  dss ON f.status_key           = dss.status_key
LEFT JOIN dw.DimRoute           dr  ON f.route_key            = dr.route_key
LEFT JOIN dw.DimPayment         dpy ON f.payment_key          = dpy.payment_key;
GO

-- ============================================================
-- 5. DUPLICATE CHECK
-- ============================================================
PRINT '=== [5] DUPLICATE CHECK ===';
SELECT
    (SELECT COUNT(*) - COUNT(DISTINCT shipment_key) FROM dw.FactDeliveryPerformance) AS Dup_shipment_key,
    (SELECT COUNT(*) - COUNT(DISTINCT shipment_id)  FROM dw.FactDeliveryPerformance) AS Dup_shipment_id,
    (SELECT COUNT(*) - COUNT(DISTINCT awb_number)   FROM dw.FactDeliveryPerformance) AS Dup_awb_number,
    (SELECT COUNT(*) - COUNT(DISTINCT customer_key) FROM dw.DimCustomer)             AS Dup_customer_key,
    (SELECT COUNT(*) - COUNT(DISTINCT customer_id)  FROM dw.DimCustomer)             AS Dup_customer_id;
GO

-- ============================================================
-- 6. KPI SUMMARY (Preview untuk Power BI)
-- ============================================================
PRINT '=== [6] KPI SUMMARY ===';
SELECT
    FORMAT(SUM(total_shipment), 'N0')           AS Total_Shipments,
    FORMAT(SUM(CAST(total_amount AS BIGINT)), 'N0')             AS Total_Revenue_IDR,
    FORMAT(AVG(CAST(total_amount AS FLOAT)), 'N0') AS Avg_Revenue_Per_Shipment,

    -- Delivery Rate
    CAST(
        SUM(CAST(is_delivered AS FLOAT)) * 100.0
        / NULLIF(SUM(total_shipment), 0)
    AS DECIMAL(5,2))                            AS Delivery_Rate_Pct,

    CAST(
        SUM(CASE WHEN is_delivered = 1 AND is_late = 0 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(CAST(is_delivered AS INT)), 0)
    AS DECIMAL(5,2))                            AS OnTime_Rate_Pct,

    -- Rata-rata keterlambatan (hanya dari yang terlambat)
    CAST(
        AVG(CASE WHEN delay_days > 0 THEN CAST(delay_days AS FLOAT) END)
    AS DECIMAL(5,2))                            AS Avg_Delay_Days_WhenLate,

    -- Failure Rate
    CAST(
        SUM(CAST(is_failed AS FLOAT)) * 100.0
        / NULLIF(SUM(total_shipment), 0)
    AS DECIMAL(5,2))                            AS Failure_Rate_Pct

FROM dw.FactDeliveryPerformance;
GO

PRINT '================================================';
PRINT 'QA Check selesai. Semua nilai Error harus = 0.';
PRINT 'Jika ada Orphan atau Error > 0, cek kembali';
PRINT 'script ETL sebelumnya.';
PRINT '================================================';
GO
