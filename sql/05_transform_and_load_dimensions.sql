-- ==============================================================================
-- File      : 05_transform_and_load_dimensions.sql
-- Tujuan    : Transformasi ekstensif (Cleansing, Formatting) & Load ke Dimensi
-- ==============================================================================

USE Logistics_DW;
GO

-- 0. RESET DATA
DELETE FROM FactDeliveryPerformance;
DELETE FROM DimDate;
DELETE FROM DimCustomer;
DELETE FROM DimBranch;
DELETE FROM DimCourier;
DELETE FROM DimService;
DELETE FROM DimPackage;
DELETE FROM DimShipmentStatus;
DELETE FROM DimRoute;
DELETE FROM DimPayment;
GO


-- 1. TRANSFORMASI: DimDate
INSERT INTO DimDate 
SELECT 
    TRY_CONVERT(INT, date_key), TRY_CONVERT(DATE, full_date), TRY_CONVERT(INT, day_number),
    LTRIM(RTRIM(day_name)), TRY_CONVERT(INT, month_number), LTRIM(RTRIM(month_name)),
    TRY_CONVERT(INT, quarter_number), TRY_CONVERT(INT, year_number), TRY_CONVERT(BIT, is_weekend)
FROM stg_DimDate;

-- 2. TRANSFORMASI: DimCustomer
INSERT INTO DimCustomer
SELECT 
    TRY_CONVERT(INT, customer_key),
    UPPER(LTRIM(RTRIM(customer_id))),
    ISNULL(NULLIF(LTRIM(RTRIM(customer_name)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(customer_type)), ''), 'Unknown'),
    CASE 
        WHEN UPPER(LTRIM(RTRIM(gender))) IN ('L', 'LAKI-LAKI', 'MALE', 'M') THEN 'Laki-laki'
        WHEN UPPER(LTRIM(RTRIM(gender))) IN ('P', 'PEREMPUAN', 'FEMALE', 'F') THEN 'Perempuan'
        ELSE 'Unknown'
    END,
    COALESCE(NULLIF(REPLACE(REPLACE(LTRIM(RTRIM(phone)), '-', ''), ' ', ''), ''), 'Tidak Ada'),
    COALESCE(NULLIF(LOWER(LTRIM(RTRIM(email))), ''), 'Tanpa Email'),
    ISNULL(NULLIF(LTRIM(RTRIM(city)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(province)), ''), 'Unknown'),
    COALESCE(
        TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(registration_date)), ''), 120),
        TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(registration_date)), ''), 103)
    ),
    CASE WHEN UPPER(LTRIM(RTRIM(is_active))) IN ('1', 'TRUE', 'YES', 'Y', 'AKTIF') THEN 1 ELSE 0 END
FROM stg_DimCustomer;

-- 3. TRANSFORMASI: DimBranch
INSERT INTO DimBranch
SELECT 
    TRY_CONVERT(INT, branch_key), UPPER(LTRIM(RTRIM(branch_id))),
    ISNULL(NULLIF(LTRIM(RTRIM(branch_name)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(branch_type)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(address)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(city)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(province)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(region)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(manager_name)), ''), 'Unknown'),
    COALESCE(TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(opening_date)), ''), 120), TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(opening_date)), ''), 103)),
    CASE WHEN UPPER(LTRIM(RTRIM(is_active))) IN ('1', 'TRUE', 'YES', 'Y') THEN 1 ELSE 0 END
FROM stg_DimBranch;

-- 4. TRANSFORMASI: DimCourier
INSERT INTO DimCourier
SELECT 
    TRY_CONVERT(INT, courier_key), UPPER(LTRIM(RTRIM(courier_id))),
    ISNULL(NULLIF(LTRIM(RTRIM(courier_name)), ''), 'Unknown Courier'),
    CASE 
        WHEN UPPER(LTRIM(RTRIM(gender))) IN ('L', 'LAKI-LAKI') THEN 'Laki-laki'
        WHEN UPPER(LTRIM(RTRIM(gender))) IN ('P', 'PEREMPUAN') THEN 'Perempuan'
        ELSE 'Unknown'
    END,
    COALESCE(NULLIF(REPLACE(LTRIM(RTRIM(phone)), '-', ''), ''), 'Tidak Ada'),
    UPPER(LTRIM(RTRIM(branch_id))),
    ISNULL(NULLIF(LTRIM(RTRIM(vehicle_type)), ''), 'Unknown'),
    COALESCE(TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(hire_date)), ''), 120), TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(hire_date)), ''), 103)),
    ISNULL(NULLIF(LTRIM(RTRIM(employee_status)), ''), 'Unknown'),
    CASE WHEN UPPER(LTRIM(RTRIM(is_active))) IN ('1', 'TRUE', 'YES') THEN 1 ELSE 0 END
FROM stg_DimCourier;

-- 5. TRANSFORMASI: DimService
INSERT INTO DimService
SELECT 
    TRY_CONVERT(INT, service_key), UPPER(LTRIM(RTRIM(service_code))),
    ISNULL(NULLIF(LTRIM(RTRIM(service_name)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(service_category)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(delivery_estimation)), ''), 'Unknown'),
    TRY_CONVERT(DECIMAL(5,1), NULLIF(REPLACE(UPPER(LTRIM(RTRIM(max_weight))), 'KG', ''), '')),
    CASE WHEN UPPER(LTRIM(RTRIM(is_cod_available))) IN ('1', 'TRUE', 'YES') THEN 1 ELSE 0 END,
    CASE WHEN UPPER(LTRIM(RTRIM(is_active))) IN ('1', 'TRUE', 'YES') THEN 1 ELSE 0 END
FROM stg_DimService;

-- 6. TRANSFORMASI: DimPackage
INSERT INTO DimPackage
SELECT 
    TRY_CONVERT(INT, package_key), UPPER(LTRIM(RTRIM(package_id))),
    ISNULL(NULLIF(LTRIM(RTRIM(package_type)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(package_category)), ''), 'Unknown'),
    TRY_CONVERT(DECIMAL(6,2), NULLIF(LTRIM(RTRIM(weight)), '')),
    ISNULL(NULLIF(LTRIM(RTRIM(weight_category)), ''), 'Unknown'),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(length_cm)), '')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(width_cm)), '')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(height_cm)), '')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(volume_cm3)), '')),
    CASE WHEN UPPER(LTRIM(RTRIM(is_fragile))) IN ('1', 'TRUE', 'YES') THEN 1 ELSE 0 END,
    CASE WHEN UPPER(LTRIM(RTRIM(is_insured))) IN ('1', 'TRUE', 'YES') THEN 1 ELSE 0 END,
    COALESCE(NULLIF(LTRIM(RTRIM(item_description)), ''), 'Tidak Ada Deskripsi')
FROM stg_DimPackage;

-- 7. TRANSFORMASI: DimShipmentStatus
INSERT INTO DimShipmentStatus
SELECT 
    TRY_CONVERT(INT, status_key), UPPER(LTRIM(RTRIM(status_code))),
    ISNULL(NULLIF(LTRIM(RTRIM(status_name)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(status_category)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(status_description)), ''), 'Unknown')
FROM stg_DimShipmentStatus;

-- 8. TRANSFORMASI: DimRoute
INSERT INTO DimRoute
SELECT 
    TRY_CONVERT(INT, route_key), UPPER(LTRIM(RTRIM(route_id))),
    ISNULL(NULLIF(LTRIM(RTRIM(origin_city)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(destination_city)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(origin_region)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(destination_region)), ''), 'Unknown'),
    TRY_CONVERT(INT, NULLIF(REPLACE(UPPER(LTRIM(RTRIM(distance_km))), 'KM', ''), '')),
    ISNULL(NULLIF(LTRIM(RTRIM(route_type)), ''), 'Unknown'),
    CASE WHEN UPPER(LTRIM(RTRIM(is_active))) IN ('1', 'TRUE', 'YES') THEN 1 ELSE 0 END
FROM stg_DimRoute;

-- 9. TRANSFORMASI: DimPayment
INSERT INTO DimPayment
SELECT 
    TRY_CONVERT(INT, payment_key), UPPER(LTRIM(RTRIM(payment_id))),
    ISNULL(NULLIF(LTRIM(RTRIM(payment_method)), ''), 'Unknown'),
    ISNULL(NULLIF(LTRIM(RTRIM(payment_channel)), ''), 'Unknown'),
    CASE 
        WHEN NULLIF(LTRIM(RTRIM(bank_name)), '') IS NOT NULL THEN LTRIM(RTRIM(bank_name))
        WHEN UPPER(LTRIM(RTRIM(payment_method))) IN ('COD', 'E-WALLET', 'CASH') THEN 'Not Applicable'
        ELSE 'Unknown'
    END,
    COALESCE(TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(payment_date)), ''), 120), TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(payment_date)), ''), 103)),
    ISNULL(NULLIF(LTRIM(RTRIM(payment_status)), ''), 'Unknown'),
    CASE WHEN UPPER(LTRIM(RTRIM(is_cod))) IN ('1', 'TRUE', 'YES') THEN 1 ELSE 0 END,
    ISNULL(NULLIF(LTRIM(RTRIM(refund_status)), ''), 'Unknown')
FROM stg_DimPayment;
GO