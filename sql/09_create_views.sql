-- ==============================================================================
-- File      : 09_create_views.sql
-- Tujuan    : Membuat Analytical Views sebagai lapisan abstraksi untuk Power BI
-- Best Practice: Analis & Power BI connect ke View, bukan langsung ke Fact/Dim
-- Jalankan  : Setelah 08_create_indexes.sql
-- ==============================================================================

USE Logistics_DW;
GO

-- ============================================================
-- VIEW 1: vw_DeliveryPerformanceSummary
-- Ringkasan performa pengiriman per transaksi — view utama Power BI
-- ============================================================
GO
CREATE OR ALTER VIEW dw.vw_DeliveryPerformanceSummary AS
SELECT
    -- Identitas Pengiriman
    f.shipment_key,
    f.shipment_id,
    f.awb_number,

    -- Dimensi Waktu
    dd_trx.full_date        AS transaction_date,
    dd_trx.day_name         AS transaction_day,
    dd_trx.month_name       AS transaction_month,
    dd_trx.month_number     AS transaction_month_num,
    dd_trx.quarter_number   AS transaction_quarter,
    dd_trx.year_number      AS transaction_year,
    dd_trx.is_weekend       AS is_weekend_transaction,

    dd_del.full_date        AS delivery_date,

    -- Dimensi Pelanggan
    c.customer_id,
    c.customer_name,
    c.customer_type,
    c.city                  AS customer_city,
    c.province              AS customer_province,

    -- Dimensi Cabang
    b.branch_id,
    b.branch_name,
    b.city                  AS branch_city,
    b.region                AS branch_region,

    -- Dimensi Kurir
    co.courier_id,
    co.courier_name,
    co.vehicle_type,
    co.employee_status,

    -- Dimensi Layanan
    sv.service_code,
    sv.service_name,
    sv.service_category,

    -- Dimensi Status
    st.status_code,
    st.status_name,
    st.status_category,

    -- Dimensi Rute
    r.origin_city,
    r.destination_city,
    r.origin_region,
    r.destination_region,
    r.route_type,
    r.distance_km,

    -- Dimensi Paket
    pk.package_type,
    pk.package_category,
    pk.weight_category,
    pk.is_fragile,
    pk.is_insured,

    -- Dimensi Pembayaran
    py.payment_method,
    py.payment_channel,
    py.bank_name,
    py.is_cod,

    -- Measures
    f.total_shipment,
    f.estimated_days,
    f.actual_days,
    f.delay_days,
    f.package_weight,
    f.shipping_fee,
    f.insurance_fee,
    f.discount_amount,
    f.total_amount,

    -- Flags
    f.is_delivered,
    f.is_late,
    f.is_failed,
    f.is_returned,
    f.is_cancelled
FROM dw.FactDeliveryPerformance f
JOIN dw.DimDate           dd_trx  ON f.transaction_date_key = dd_trx.date_key
LEFT JOIN dw.DimDate      dd_del  ON f.delivery_date_key    = dd_del.date_key
JOIN dw.DimCustomer       c       ON f.customer_key         = c.customer_key
JOIN dw.DimBranch         b       ON f.branch_key           = b.branch_key
JOIN dw.DimCourier        co      ON f.courier_key          = co.courier_key
JOIN dw.DimService        sv      ON f.service_key          = sv.service_key
JOIN dw.DimShipmentStatus st      ON f.status_key           = st.status_key
JOIN dw.DimRoute          r       ON f.route_key            = r.route_key
JOIN dw.DimPackage        pk      ON f.package_key          = pk.package_key
JOIN dw.DimPayment        py      ON f.payment_key          = py.payment_key;
GO
PRINT 'vw_DeliveryPerformanceSummary dibuat';

-- ============================================================
-- VIEW 2: vw_CourierPerformance
-- ============================================================
GO
CREATE OR ALTER VIEW dw.vw_CourierPerformance AS
SELECT
    co.courier_id,
    co.courier_name,
    co.vehicle_type,
    co.employee_status,
    b.branch_name,
    b.region,

    COUNT(f.shipment_key)                                           AS total_pengiriman,
    SUM(CAST(f.is_delivered AS INT))                                AS total_delivered,
    SUM(CAST(f.is_late AS INT))                                     AS total_terlambat,
    SUM(CAST(f.is_failed AS INT))                                   AS total_gagal,

    CAST(
        SUM(CAST(f.is_delivered AS FLOAT)) * 100.0
        / NULLIF(COUNT(f.shipment_key), 0)
    AS DECIMAL(5,2))                                                AS delivery_rate_pct,

    CAST(
        SUM(CASE WHEN f.is_delivered = 1 AND f.is_late = 0 THEN 1.0 ELSE 0 END) * 100.0
        / NULLIF(SUM(CAST(f.is_delivered AS FLOAT)), 0)
    AS DECIMAL(5,2))                                                AS ontime_rate_pct,

    CAST(AVG(
        CASE WHEN f.delay_days > 0 THEN CAST(f.delay_days AS FLOAT) END
    ) AS DECIMAL(5,2))                                              AS avg_delay_days,

    SUM(CAST(f.total_amount AS BIGINT))                             AS total_revenue
FROM dw.FactDeliveryPerformance f
JOIN dw.DimCourier co ON f.courier_key = co.courier_key
JOIN dw.DimBranch  b  ON f.branch_key  = b.branch_key
GROUP BY
    co.courier_id, co.courier_name, co.vehicle_type,
    co.employee_status, b.branch_name, b.region;
GO
PRINT 'vw_CourierPerformance dibuat';

-- ============================================================
-- VIEW 3: vw_BranchRevenue
-- ============================================================
GO
CREATE OR ALTER VIEW dw.vw_BranchRevenue AS
SELECT
    b.branch_id,
    b.branch_name,
    b.city              AS branch_city,
    b.province          AS branch_province,
    b.region,
    b.branch_type,

    dd.year_number,
    dd.quarter_number,
    dd.month_number,
    dd.month_name,

    COUNT(f.shipment_key)                                           AS total_pengiriman,
    SUM(CAST(f.total_amount AS BIGINT))                             AS total_revenue,
    SUM(CAST(f.shipping_fee AS BIGINT))                             AS total_shipping_fee,
    SUM(CAST(f.discount_amount AS BIGINT))                          AS total_diskon,
    AVG(CAST(f.total_amount AS FLOAT))                              AS avg_revenue_per_shipment,
    SUM(CAST(f.is_delivered AS INT))                                AS total_delivered,
    SUM(CAST(f.is_failed AS INT))                                   AS total_gagal,

    CAST(
        SUM(CAST(f.is_delivered AS FLOAT)) * 100.0
        / NULLIF(COUNT(f.shipment_key), 0)
    AS DECIMAL(5,2))                                                AS delivery_rate_pct
FROM dw.FactDeliveryPerformance f
JOIN dw.DimBranch b  ON f.branch_key           = b.branch_key
JOIN dw.DimDate   dd ON f.transaction_date_key  = dd.date_key
GROUP BY
    b.branch_id, b.branch_name, b.city, b.province,
    b.region, b.branch_type,
    dd.year_number, dd.quarter_number, dd.month_number, dd.month_name;
GO
PRINT 'vw_BranchRevenue dibuat';

-- ============================================================
-- VIEW 4: vw_MonthlyTrend
-- ============================================================
GO
CREATE OR ALTER VIEW dw.vw_MonthlyTrend AS
SELECT
    dd.year_number,
    dd.quarter_number,
    dd.month_number,
    dd.month_name,

    sv.service_category,
    st.status_category,

    COUNT(f.shipment_key)                                           AS total_pengiriman,
    SUM(CAST(f.total_amount AS BIGINT))                             AS total_revenue,
    SUM(CAST(f.is_delivered AS INT))                                AS total_delivered,
    SUM(CAST(f.is_late AS INT))                                     AS total_terlambat,
    SUM(CAST(f.is_failed AS INT))                                   AS total_gagal,
    SUM(CAST(f.is_returned AS INT))                                 AS total_retur,
    SUM(CAST(f.is_cancelled AS INT))                                AS total_batal,
    AVG(CAST(f.actual_days AS FLOAT))                               AS avg_actual_days,
    AVG(CAST(f.delay_days  AS FLOAT))                               AS avg_delay_days
FROM dw.FactDeliveryPerformance f
JOIN dw.DimDate           dd ON f.transaction_date_key = dd.date_key
JOIN dw.DimService        sv ON f.service_key          = sv.service_key
JOIN dw.DimShipmentStatus st ON f.status_key           = st.status_key
GROUP BY
    dd.year_number, dd.quarter_number, dd.month_number, dd.month_name,
    sv.service_category, st.status_category;
GO
PRINT 'vw_MonthlyTrend dibuat';

-- ============================================================
-- VIEW 5: vw_ServiceAnalysis
-- ============================================================
GO
CREATE OR ALTER VIEW dw.vw_ServiceAnalysis AS
SELECT
    sv.service_code,
    sv.service_name,
    sv.service_category,
    sv.delivery_estimation,
    sv.max_weight,
    sv.is_cod_available,

    COUNT(f.shipment_key)                                           AS total_pengiriman,
    SUM(CAST(f.total_amount AS BIGINT))                             AS total_revenue,
    AVG(CAST(f.total_amount AS FLOAT))                              AS avg_revenue,
    SUM(CAST(f.is_delivered AS INT))                                AS total_delivered,
    SUM(CAST(f.is_late AS INT))                                     AS total_terlambat,

    CAST(
        SUM(CAST(f.is_delivered AS FLOAT)) * 100.0
        / NULLIF(COUNT(f.shipment_key), 0)
    AS DECIMAL(5,2))                                                AS delivery_rate_pct,

    CAST(
        SUM(CASE WHEN f.is_delivered = 1 AND f.is_late = 0 THEN 1.0 ELSE 0 END) * 100.0
        / NULLIF(SUM(CAST(f.is_delivered AS FLOAT)), 0)
    AS DECIMAL(5,2))                                                AS ontime_rate_pct,

    AVG(CAST(f.actual_days AS FLOAT))                               AS avg_actual_days,
    AVG(CAST(f.package_weight AS FLOAT))                            AS avg_package_weight
FROM dw.FactDeliveryPerformance f
JOIN dw.DimService sv ON f.service_key = sv.service_key
GROUP BY
    sv.service_code, sv.service_name, sv.service_category,
    sv.delivery_estimation, sv.max_weight, sv.is_cod_available;
GO
PRINT 'vw_ServiceAnalysis dibuat';

-- ============================================================
-- VERIFIKASI: Tampilkan semua view yang berhasil dibuat
-- ============================================================
SELECT
    v.name          AS ViewName,
    s.name          AS Schema_Name,
    v.create_date   AS CreatedAt
FROM sys.views      v
JOIN sys.schemas    s ON v.schema_id = s.schema_id
WHERE s.name = 'dw'
ORDER BY v.name;
GO

PRINT '================================================';
PRINT 'Semua Analytical Views berhasil dibuat:';
PRINT '  1. vw_DeliveryPerformanceSummary (main view)';
PRINT '  2. vw_CourierPerformance';
PRINT '  3. vw_BranchRevenue';
PRINT '  4. vw_MonthlyTrend';
PRINT '  5. vw_ServiceAnalysis';
PRINT '';
PRINT 'Power BI: Connect ke view-view ini, bukan';
PRINT 'langsung ke tabel Fact/Dim.';
PRINT '================================================';
GO