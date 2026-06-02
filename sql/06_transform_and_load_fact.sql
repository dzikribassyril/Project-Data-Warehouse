-- ==============================================================================
-- File      : 06_transform_and_load_fact.sql
-- Tujuan    : Transformasi, Kalkulasi Business Rules, & Load ke Tabel Fakta
-- ==============================================================================

USE Logistics_DW;
GO

-- 1. Membersihkan data
DELETE FROM FactDeliveryPerformance;
GO

-- 2. Proses ETL Menggunakan CTE (Common Table Expression)
WITH CleanedStaging AS (
    -- Sub-query ini bertugas mengubah semua tipe VARCHAR menjadi tipe data asli (INT, DECIMAL)
    SELECT 
        TRY_CONVERT(INT, shipment_key) AS shipment_key,
        UPPER(LTRIM(RTRIM(shipment_id))) AS shipment_id,
        UPPER(LTRIM(RTRIM(awb_number))) AS awb_number,
        TRY_CONVERT(INT, transaction_date_key) AS transaction_date_key,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(pickup_date_key)), '')) AS pickup_date_key,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(delivery_date_key)), '')) AS delivery_date_key,
        TRY_CONVERT(INT, customer_key) AS customer_key,
        TRY_CONVERT(INT, branch_key) AS branch_key,
        TRY_CONVERT(INT, courier_key) AS courier_key,
        TRY_CONVERT(INT, service_key) AS service_key,
        TRY_CONVERT(INT, package_key) AS package_key,
        TRY_CONVERT(INT, status_key) AS status_key,
        TRY_CONVERT(INT, route_key) AS route_key,
        TRY_CONVERT(INT, payment_key) AS payment_key,
        1 AS total_shipment, -- Selalu 1 untuk fungsi Count di Power BI
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(estimated_days)), '')) AS estimated_days,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(actual_days)), '')) AS actual_days,
        TRY_CONVERT(DECIMAL(6,2), NULLIF(LTRIM(RTRIM(package_weight)), '')) AS package_weight,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(shipping_fee)), '')) AS shipping_fee,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(insurance_fee)), '')) AS insurance_fee,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(discount_amount)), '')) AS discount_amount
    FROM stg_FactDeliveryPerformance
)
-- Memasukkan data ke Tabel Fakta sambil menjalankan Kalkulasi Aturan Bisnis
INSERT INTO FactDeliveryPerformance
SELECT 
    c.shipment_key,
    c.shipment_id,
    c.awb_number,
    c.transaction_date_key,
    c.pickup_date_key,
    c.delivery_date_key,
    c.customer_key,
    c.branch_key,
    c.courier_key,
    c.service_key,
    c.package_key,
    c.status_key,
    c.route_key,
    c.payment_key,
    
    -- Measures Murni
    c.total_shipment,
    c.estimated_days,
    c.actual_days,
    
    -- KALKULASI: delay_days
    CASE 
        WHEN c.actual_days IS NULL THEN NULL
        WHEN c.actual_days > c.estimated_days THEN (c.actual_days - c.estimated_days)
        ELSE 0 
    END AS delay_days,
    
    c.package_weight,
    c.shipping_fee,
    c.insurance_fee,
    c.discount_amount,
    
    -- KALKULASI: total_amount = shipping + insurance - discount
    (ISNULL(c.shipping_fee, 0) + ISNULL(c.insurance_fee, 0) - ISNULL(c.discount_amount, 0)) AS total_amount,
    
    -- KALKULASI FLAGS (Join dengan DimShipmentStatus untuk mengecek kode)
    CASE WHEN UPPER(dss.status_code) = 'DELIVERED' THEN 1 ELSE 0 END AS is_delivered,
    CASE WHEN (c.actual_days > c.estimated_days) THEN 1 ELSE 0 END AS is_late,
    CASE WHEN UPPER(dss.status_code) = 'FAILED' THEN 1 ELSE 0 END AS is_failed,
    CASE WHEN UPPER(dss.status_code) = 'RETURNED' THEN 1 ELSE 0 END AS is_returned,
    CASE WHEN UPPER(dss.status_code) = 'CANCELLED' THEN 1 ELSE 0 END AS is_cancelled

FROM CleanedStaging c
-- Join ke Dimensi Status untuk mendapatkan status_code yang valid
LEFT JOIN DimShipmentStatus dss ON c.status_key = dss.status_key;
GO