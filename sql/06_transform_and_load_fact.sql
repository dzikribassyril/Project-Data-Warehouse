-- ==============================================================================
-- File      : 06_transform_and_load_fact.sql
-- Tujuan    : Transformasi, Kalkulasi Business Rules, & Load ke Tabel Fakta
-- Catatan   : Source: schema [stg] → Target: schema [dw]
--             Flags & delay_days dikalkulasi ulang dari data bersih,
--             BUKAN diambil mentah dari staging (lebih trustworthy)
-- ==============================================================================

USE Logistics_DW;
GO

-- ============================================================
-- 1. RESET FACT TABLE
-- ============================================================
DELETE FROM dw.FactDeliveryPerformance;
PRINT 'FactDeliveryPerformance berhasil dikosongkan.';
GO

-- ============================================================
-- 2. ETL MENGGUNAKAN CTE
-- ============================================================
BEGIN TRY

    WITH CleanedStaging AS (
        SELECT
            TRY_CONVERT(INT, LTRIM(RTRIM(shipment_key)))                            AS shipment_key,
            UPPER(LTRIM(RTRIM(shipment_id)))                                        AS shipment_id,
            UPPER(LTRIM(RTRIM(awb_number)))                                         AS awb_number,
            TRY_CONVERT(INT, LTRIM(RTRIM(transaction_date_key)))                    AS transaction_date_key,
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(pickup_date_key)),   ''))           AS pickup_date_key,
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(delivery_date_key)), ''))           AS delivery_date_key,
            TRY_CONVERT(INT, LTRIM(RTRIM(customer_key)))                            AS customer_key,
            TRY_CONVERT(INT, LTRIM(RTRIM(branch_key)))                              AS branch_key,
            TRY_CONVERT(INT, LTRIM(RTRIM(courier_key)))                             AS courier_key,
            TRY_CONVERT(INT, LTRIM(RTRIM(service_key)))                             AS service_key,
            TRY_CONVERT(INT, LTRIM(RTRIM(package_key)))                             AS package_key,
            TRY_CONVERT(INT, LTRIM(RTRIM(status_key)))                              AS status_key,
            TRY_CONVERT(INT, LTRIM(RTRIM(route_key)))                               AS route_key,
            TRY_CONVERT(INT, LTRIM(RTRIM(payment_key)))                             AS payment_key,
            TRY_CONVERT(INT,         NULLIF(LTRIM(RTRIM(estimated_days)),  ''))     AS estimated_days,
            TRY_CONVERT(INT,         NULLIF(LTRIM(RTRIM(actual_days)),     ''))     AS actual_days,
            TRY_CONVERT(DECIMAL(6,2),NULLIF(LTRIM(RTRIM(package_weight)), ''))      AS package_weight,
            TRY_CONVERT(INT,         NULLIF(LTRIM(RTRIM(shipping_fee)),   ''))      AS shipping_fee,
            TRY_CONVERT(INT,         NULLIF(LTRIM(RTRIM(insurance_fee)),  ''))      AS insurance_fee,
            TRY_CONVERT(INT,         NULLIF(LTRIM(RTRIM(discount_amount)),''))      AS discount_amount
        FROM stg.FactDeliveryPerformance
        WHERE TRY_CONVERT(INT, LTRIM(RTRIM(shipment_key))) IS NOT NULL
    )
    INSERT INTO dw.FactDeliveryPerformance
    SELECT
        c.shipment_key,
        c.shipment_id,
        c.awb_number,

        -- Date Keys (Role-Playing DimDate)
        c.transaction_date_key,
        c.pickup_date_key,
        c.delivery_date_key,

        -- Dimension Keys
        c.customer_key,
        c.branch_key,
        c.courier_key,
        c.service_key,
        c.package_key,
        c.status_key,
        c.route_key,
        c.payment_key,

        -- Measures
        1                                           AS total_shipment,
        c.estimated_days,
        c.actual_days,

        -- KALKULASI: delay_days (NULL jika belum selesai, 0 jika tepat waktu)
        CASE
            WHEN c.actual_days IS NULL              THEN NULL
            WHEN c.actual_days > c.estimated_days   THEN c.actual_days - c.estimated_days
            ELSE 0
        END                                         AS delay_days,

        c.package_weight,
        ISNULL(c.shipping_fee,    0)                AS shipping_fee,
        ISNULL(c.insurance_fee,   0)                AS insurance_fee,
        ISNULL(c.discount_amount, 0)                AS discount_amount,

        -- KALKULASI: total_amount
        ISNULL(c.shipping_fee, 0)
            + ISNULL(c.insurance_fee, 0)
            - ISNULL(c.discount_amount, 0)          AS total_amount,

        -- FLAGS: dikalkulasi dari status_code (bukan dari staging)
        CASE WHEN UPPER(dss.status_code) = 'DELIVERED'  THEN 1 ELSE 0 END  AS is_delivered,

        -- FIX: is_late harus NULL-safe — hanya 1 jika actual_days tersedia DAN lebih besar
        CASE
            WHEN c.actual_days IS NULL              THEN 0
            WHEN c.actual_days > c.estimated_days   THEN 1
            ELSE 0
        END                                         AS is_late,

        CASE WHEN UPPER(dss.status_code) = 'FAILED'     THEN 1 ELSE 0 END  AS is_failed,
        CASE WHEN UPPER(dss.status_code) = 'RETURNED'   THEN 1 ELSE 0 END  AS is_returned,
        CASE WHEN UPPER(dss.status_code) = 'CANCELLED'  THEN 1 ELSE 0 END  AS is_cancelled

    FROM CleanedStaging c
    LEFT JOIN dw.DimShipmentStatus dss ON c.status_key = dss.status_key;

    PRINT 'FactDeliveryPerformance loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' baris';

END TRY
BEGIN CATCH
    PRINT 'ERROR FactDeliveryPerformance: ' + ERROR_MESSAGE();
    PRINT 'Error Line   : ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
GO

PRINT '================================================';
PRINT 'Transform & Load Fact selesai.';
PRINT 'Lanjutkan ke: 07_check_etl_result.sql';
PRINT '================================================';
GO
