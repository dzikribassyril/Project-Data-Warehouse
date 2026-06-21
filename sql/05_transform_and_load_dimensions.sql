-- ==============================================================================
-- File      : 05_transform_and_load_dimensions.sql
-- Tujuan    : Transformasi (Cleansing, Standardisasi) & Load ke Tabel Dimensi
-- Catatan   : Source: schema [stg] → Target: schema [dw]
-- ==============================================================================

USE Logistics_DW;
GO

-- ============================================================
-- 0. RESET DATA DW (urutan: Fact dulu karena ada FK)
-- ============================================================
DELETE FROM dw.FactDeliveryPerformance;
DELETE FROM dw.DimDate;
DELETE FROM dw.DimCustomer;
DELETE FROM dw.DimBranch;
DELETE FROM dw.DimCourier;
DELETE FROM dw.DimService;
DELETE FROM dw.DimPackage;
DELETE FROM dw.DimShipmentStatus;
DELETE FROM dw.DimRoute;
DELETE FROM dw.DimPayment;
PRINT 'Tabel DW berhasil dikosongkan.';
GO

-- ============================================================
-- HELPER: Cek jumlah baris staging sebelum transform
-- ============================================================
SELECT 'STAGING ROW COUNT' AS Info,
    (SELECT COUNT(*) FROM stg.DimDate)              AS DimDate,
    (SELECT COUNT(*) FROM stg.DimCustomer)          AS DimCustomer,
    (SELECT COUNT(*) FROM stg.DimBranch)            AS DimBranch,
    (SELECT COUNT(*) FROM stg.DimCourier)           AS DimCourier,
    (SELECT COUNT(*) FROM stg.DimService)           AS DimService,
    (SELECT COUNT(*) FROM stg.DimPackage)           AS DimPackage,
    (SELECT COUNT(*) FROM stg.DimShipmentStatus)    AS DimShipmentStatus,
    (SELECT COUNT(*) FROM stg.DimRoute)             AS DimRoute,
    (SELECT COUNT(*) FROM stg.DimPayment)           AS DimPayment;
GO

-- ============================================================
-- 1. TRANSFORM & LOAD: DimDate
-- ============================================================
BEGIN TRY
    INSERT INTO dw.DimDate
    SELECT
        TRY_CONVERT(INT, LTRIM(RTRIM(date_key))),
        TRY_CONVERT(DATE, LTRIM(RTRIM(full_date)), 120),
        TRY_CONVERT(INT, LTRIM(RTRIM(day_number))),
        LTRIM(RTRIM(day_name)),
        TRY_CONVERT(INT, LTRIM(RTRIM(month_number))),
        LTRIM(RTRIM(month_name)),
        TRY_CONVERT(INT, LTRIM(RTRIM(quarter_number))),
        TRY_CONVERT(INT, LTRIM(RTRIM(year_number))),
        CASE WHEN LTRIM(RTRIM(is_weekend)) IN ('1', 'True', 'TRUE') THEN 1 ELSE 0 END
    FROM stg.DimDate
    WHERE LTRIM(RTRIM(date_key)) IS NOT NULL
      AND TRY_CONVERT(INT, LTRIM(RTRIM(date_key))) IS NOT NULL;

    PRINT '1/9 - DimDate loaded     : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' baris';
END TRY
BEGIN CATCH
    PRINT 'ERROR DimDate: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- 2. TRANSFORM & LOAD: DimCustomer
-- ============================================================
BEGIN TRY
    INSERT INTO dw.DimCustomer
    SELECT
        TRY_CONVERT(INT, LTRIM(RTRIM(customer_key))),
        UPPER(LTRIM(RTRIM(customer_id))),
        ISNULL(NULLIF(LTRIM(RTRIM(customer_name)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(customer_type)), ''), 'Unknown'),
        -- Standardisasi gender
        CASE
            WHEN UPPER(LTRIM(RTRIM(gender))) IN ('L', 'LAKI-LAKI', 'MALE', 'M') THEN 'Laki-laki'
            WHEN UPPER(LTRIM(RTRIM(gender))) IN ('P', 'PEREMPUAN', 'FEMALE', 'F') THEN 'Perempuan'
            ELSE 'Unknown'
        END,
        NULLIF(REPLACE(REPLACE(LTRIM(RTRIM(phone)), '-', ''), ' ', ''), ''),
        NULLIF(LOWER(LTRIM(RTRIM(email))), ''),
        ISNULL(NULLIF(LTRIM(RTRIM(city)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(province)), ''), 'Unknown'),
        COALESCE(
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(registration_date)), ''), 120),
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(registration_date)), ''), 103)
        ),
        CASE WHEN LTRIM(RTRIM(is_active)) IN ('1', 'True', 'TRUE') THEN 1 ELSE 0 END
    FROM stg.DimCustomer
    WHERE TRY_CONVERT(INT, LTRIM(RTRIM(customer_key))) IS NOT NULL;

    PRINT '2/9 - DimCustomer loaded : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' baris';
END TRY
BEGIN CATCH
    PRINT 'ERROR DimCustomer: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- 3. TRANSFORM & LOAD: DimBranch
-- ============================================================
BEGIN TRY
    INSERT INTO dw.DimBranch
    SELECT
        TRY_CONVERT(INT, LTRIM(RTRIM(branch_key))),
        UPPER(LTRIM(RTRIM(branch_id))),
        ISNULL(NULLIF(LTRIM(RTRIM(branch_name)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(branch_type)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(address)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(city)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(province)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(region)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(manager_name)), ''), 'Unknown'),
        COALESCE(
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(opening_date)), ''), 120),
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(opening_date)), ''), 103)
        ),
        CASE WHEN LTRIM(RTRIM(is_active)) IN ('1', 'True', 'TRUE') THEN 1 ELSE 0 END
    FROM stg.DimBranch
    WHERE TRY_CONVERT(INT, LTRIM(RTRIM(branch_key))) IS NOT NULL;

    PRINT '3/9 - DimBranch loaded   : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' baris';
END TRY
BEGIN CATCH
    PRINT 'ERROR DimBranch: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- 4. TRANSFORM & LOAD: DimCourier
-- ============================================================
BEGIN TRY
    INSERT INTO dw.DimCourier
    SELECT
        TRY_CONVERT(INT, LTRIM(RTRIM(courier_key))),
        UPPER(LTRIM(RTRIM(courier_id))),
        ISNULL(NULLIF(LTRIM(RTRIM(courier_name)), ''), 'Unknown'),
        CASE
            WHEN UPPER(LTRIM(RTRIM(gender))) IN ('L', 'LAKI-LAKI') THEN 'Laki-laki'
            WHEN UPPER(LTRIM(RTRIM(gender))) IN ('P', 'PEREMPUAN') THEN 'Perempuan'
            ELSE 'Unknown'
        END,
        ISNULL(NULLIF(REPLACE(LTRIM(RTRIM(phone)), '-', ''), ''), 'Tidak Ada'),
        UPPER(LTRIM(RTRIM(branch_id))),
        ISNULL(NULLIF(LTRIM(RTRIM(vehicle_type)), ''), 'Unknown'),
        COALESCE(
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(hire_date)), ''), 120),
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(hire_date)), ''), 103)
        ),
        ISNULL(NULLIF(LTRIM(RTRIM(employee_status)), ''), 'Unknown'),
        CASE WHEN LTRIM(RTRIM(is_active)) IN ('1', 'True', 'TRUE') THEN 1 ELSE 0 END
    FROM stg.DimCourier
    WHERE TRY_CONVERT(INT, LTRIM(RTRIM(courier_key))) IS NOT NULL;

    PRINT '4/9 - DimCourier loaded  : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' baris';
END TRY
BEGIN CATCH
    PRINT 'ERROR DimCourier: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- 5. TRANSFORM & LOAD: DimService
-- ============================================================
BEGIN TRY
    INSERT INTO dw.DimService
    SELECT
        TRY_CONVERT(INT, LTRIM(RTRIM(service_key))),
        UPPER(LTRIM(RTRIM(service_code))),
        ISNULL(NULLIF(LTRIM(RTRIM(service_name)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(service_category)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(delivery_estimation)), ''), 'Unknown'),
        TRY_CONVERT(DECIMAL(5,1), NULLIF(LTRIM(RTRIM(max_weight)), '')),
        CASE WHEN LTRIM(RTRIM(is_cod_available)) IN ('1', 'True', 'TRUE') THEN 1 ELSE 0 END,
        CASE WHEN LTRIM(RTRIM(is_active)) IN ('1', 'True', 'TRUE') THEN 1 ELSE 0 END
    FROM stg.DimService
    WHERE TRY_CONVERT(INT, LTRIM(RTRIM(service_key))) IS NOT NULL;

    PRINT '5/9 - DimService loaded  : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' baris';
END TRY
BEGIN CATCH
    PRINT 'ERROR DimService: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- 6. TRANSFORM & LOAD: DimPackage
-- ============================================================
BEGIN TRY
    INSERT INTO dw.DimPackage
    SELECT
        TRY_CONVERT(INT, LTRIM(RTRIM(package_key))),
        UPPER(LTRIM(RTRIM(package_id))),
        ISNULL(NULLIF(LTRIM(RTRIM(package_type)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(package_category)), ''), 'Unknown'),
        TRY_CONVERT(DECIMAL(6,2), NULLIF(LTRIM(RTRIM(weight)), '')),
        ISNULL(NULLIF(LTRIM(RTRIM(weight_category)), ''), 'Unknown'),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(length_cm)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(width_cm)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(height_cm)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(volume_cm3)), '')),
        CASE WHEN LTRIM(RTRIM(is_fragile)) IN ('1', 'True', 'TRUE') THEN 1 ELSE 0 END,
        CASE WHEN LTRIM(RTRIM(is_insured)) IN ('1', 'True', 'TRUE') THEN 1 ELSE 0 END,
        -- item_description: tetap NULL jika kosong (sesuai dokumentasi)
        NULLIF(LTRIM(RTRIM(item_description)), '')
    FROM stg.DimPackage
    WHERE TRY_CONVERT(INT, LTRIM(RTRIM(package_key))) IS NOT NULL;

    PRINT '6/9 - DimPackage loaded  : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' baris';
END TRY
BEGIN CATCH
    PRINT 'ERROR DimPackage: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- 7. TRANSFORM & LOAD: DimShipmentStatus
-- ============================================================
BEGIN TRY
    INSERT INTO dw.DimShipmentStatus
    SELECT
        TRY_CONVERT(INT, LTRIM(RTRIM(status_key))),
        UPPER(LTRIM(RTRIM(status_code))),
        ISNULL(NULLIF(LTRIM(RTRIM(status_name)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(status_category)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(status_description)), ''), 'Unknown')
    FROM stg.DimShipmentStatus
    WHERE TRY_CONVERT(INT, LTRIM(RTRIM(status_key))) IS NOT NULL;

    PRINT '7/9 - DimStatus loaded   : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' baris';
END TRY
BEGIN CATCH
    PRINT 'ERROR DimShipmentStatus: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- 8. TRANSFORM & LOAD: DimRoute
-- ============================================================
BEGIN TRY
    INSERT INTO dw.DimRoute
    SELECT
        TRY_CONVERT(INT, LTRIM(RTRIM(route_key))),
        UPPER(LTRIM(RTRIM(route_id))),
        ISNULL(NULLIF(LTRIM(RTRIM(origin_city)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(destination_city)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(origin_region)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(destination_region)), ''), 'Unknown'),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(distance_km)), '')),
        ISNULL(NULLIF(LTRIM(RTRIM(route_type)), ''), 'Unknown'),
        CASE WHEN LTRIM(RTRIM(is_active)) IN ('1', 'True', 'TRUE') THEN 1 ELSE 0 END
    FROM stg.DimRoute
    WHERE TRY_CONVERT(INT, LTRIM(RTRIM(route_key))) IS NOT NULL;

    PRINT '8/9 - DimRoute loaded    : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' baris';
END TRY
BEGIN CATCH
    PRINT 'ERROR DimRoute: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- 9. TRANSFORM & LOAD: DimPayment
-- ============================================================
BEGIN TRY
    INSERT INTO dw.DimPayment
    SELECT
        TRY_CONVERT(INT, LTRIM(RTRIM(payment_key))),
        UPPER(LTRIM(RTRIM(payment_id))),
        ISNULL(NULLIF(LTRIM(RTRIM(payment_method)), ''), 'Unknown'),
        ISNULL(NULLIF(LTRIM(RTRIM(payment_channel)), ''), 'Unknown'),
        -- bank_name: tetap NULL jika E-Wallet atau COD (sesuai dokumentasi)
        NULLIF(LTRIM(RTRIM(bank_name)), ''),
        COALESCE(
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(payment_date)), ''), 120),
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(payment_date)), ''), 103)
        ),
        ISNULL(NULLIF(LTRIM(RTRIM(payment_status)), ''), 'Unknown'),
        CASE WHEN LTRIM(RTRIM(is_cod)) IN ('1', 'True', 'TRUE') THEN 1 ELSE 0 END,
        ISNULL(NULLIF(LTRIM(RTRIM(refund_status)), ''), 'Tidak Ada')
    FROM stg.DimPayment
    WHERE TRY_CONVERT(INT, LTRIM(RTRIM(payment_key))) IS NOT NULL;

    PRINT '9/9 - DimPayment loaded  : ' + CAST(@@ROWCOUNT AS VARCHAR) + ' baris';
END TRY
BEGIN CATCH
    PRINT 'ERROR DimPayment: ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- VALIDASI: Ringkasan jumlah baris setelah load
-- ============================================================
SELECT 'DW ROW COUNT AFTER LOAD' AS Info,
    (SELECT COUNT(*) FROM dw.DimDate)           AS DimDate,
    (SELECT COUNT(*) FROM dw.DimCustomer)       AS DimCustomer,
    (SELECT COUNT(*) FROM dw.DimBranch)         AS DimBranch,
    (SELECT COUNT(*) FROM dw.DimCourier)        AS DimCourier,
    (SELECT COUNT(*) FROM dw.DimService)        AS DimService,
    (SELECT COUNT(*) FROM dw.DimPackage)        AS DimPackage,
    (SELECT COUNT(*) FROM dw.DimShipmentStatus) AS DimShipmentStatus,
    (SELECT COUNT(*) FROM dw.DimRoute)          AS DimRoute,
    (SELECT COUNT(*) FROM dw.DimPayment)        AS DimPayment;
GO

PRINT '================================================';
PRINT 'Transform & Load Dimensi selesai.';
PRINT 'Lanjutkan ke: 06_transform_and_load_fact.sql';
PRINT '================================================';
GO
