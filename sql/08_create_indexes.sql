-- ==============================================================================
-- File      : 08_create_indexes.sql
-- Tujuan    : Membuat Index untuk optimasi performa query & Power BI
-- Jalankan  : Setelah 07_check_etl_result.sql (data sudah terisi)
-- Catatan   : - PK sudah otomatis clustered index
--             - Script ini menambahkan non-clustered index di FK & kolom filter
-- ==============================================================================

USE Logistics_DW;
GO

-- ============================================================
-- FACT TABLE: Index di semua Foreign Key
-- ============================================================

-- Date Keys (Role-Playing — 3 FK ke DimDate)
CREATE NONCLUSTERED INDEX IX_Fact_TransactionDate
    ON dw.FactDeliveryPerformance (transaction_date_key)
    INCLUDE (total_shipment, total_amount, is_delivered, is_late);
PRINT 'IX_Fact_TransactionDate dibuat';

CREATE NONCLUSTERED INDEX IX_Fact_PickupDate
    ON dw.FactDeliveryPerformance (pickup_date_key);
PRINT 'IX_Fact_PickupDate dibuat';

CREATE NONCLUSTERED INDEX IX_Fact_DeliveryDate
    ON dw.FactDeliveryPerformance (delivery_date_key);
PRINT 'IX_Fact_DeliveryDate dibuat';

-- Dimension Keys
CREATE NONCLUSTERED INDEX IX_Fact_Customer
    ON dw.FactDeliveryPerformance (customer_key)
    INCLUDE (total_amount, is_delivered);
PRINT 'IX_Fact_Customer dibuat';

CREATE NONCLUSTERED INDEX IX_Fact_Branch
    ON dw.FactDeliveryPerformance (branch_key)
    INCLUDE (total_shipment, total_amount);
PRINT 'IX_Fact_Branch dibuat';

CREATE NONCLUSTERED INDEX IX_Fact_Courier
    ON dw.FactDeliveryPerformance (courier_key)
    INCLUDE (is_delivered, is_late, delay_days);
PRINT 'IX_Fact_Courier dibuat';

CREATE NONCLUSTERED INDEX IX_Fact_Service
    ON dw.FactDeliveryPerformance (service_key)
    INCLUDE (total_shipment, total_amount);
PRINT 'IX_Fact_Service dibuat';

CREATE NONCLUSTERED INDEX IX_Fact_Status
    ON dw.FactDeliveryPerformance (status_key)
    INCLUDE (total_shipment, is_delivered, is_late, is_failed);
PRINT 'IX_Fact_Status dibuat';

CREATE NONCLUSTERED INDEX IX_Fact_Route
    ON dw.FactDeliveryPerformance (route_key)
    INCLUDE (total_shipment, actual_days);
PRINT 'IX_Fact_Route dibuat';

-- Composite: tanggal + status
CREATE NONCLUSTERED INDEX IX_Fact_Date_Status
    ON dw.FactDeliveryPerformance (transaction_date_key, status_key)
    INCLUDE (total_shipment, total_amount, is_delivered, is_late);
PRINT 'IX_Fact_Date_Status dibuat';

-- Flag columns
CREATE NONCLUSTERED INDEX IX_Fact_Flags
    ON dw.FactDeliveryPerformance (is_delivered, is_late, is_failed, is_returned, is_cancelled)
    INCLUDE (total_shipment, total_amount, delay_days);
PRINT 'IX_Fact_Flags dibuat';

GO

-- ============================================================
-- DIMENSION TABLES: Index di business key & kolom filter umum
-- ============================================================

-- DimCustomer
CREATE NONCLUSTERED INDEX IX_Customer_Province
    ON dw.DimCustomer (province)
    INCLUDE (customer_name, customer_type, is_active);
PRINT 'IX_Customer_Province dibuat';

CREATE NONCLUSTERED INDEX IX_Customer_Type
    ON dw.DimCustomer (customer_type, is_active);
PRINT 'IX_Customer_Type dibuat';

-- DimBranch
CREATE NONCLUSTERED INDEX IX_Branch_Region
    ON dw.DimBranch (region, is_active)
    INCLUDE (branch_name, city);
PRINT 'IX_Branch_Region dibuat';

-- DimCourier
CREATE NONCLUSTERED INDEX IX_Courier_Branch
    ON dw.DimCourier (branch_id, is_active)
    INCLUDE (courier_name, vehicle_type, employee_status);
PRINT 'IX_Courier_Branch dibuat';

CREATE NONCLUSTERED INDEX IX_Courier_VehicleType
    ON dw.DimCourier (vehicle_type)
    INCLUDE (courier_name, employee_status);
PRINT 'IX_Courier_VehicleType dibuat';

-- DimDate
CREATE NONCLUSTERED INDEX IX_Date_YearMonth
    ON dw.DimDate (year_number, month_number)
    INCLUDE (full_date, quarter_number, is_weekend);
PRINT 'IX_Date_YearMonth dibuat';

CREATE NONCLUSTERED INDEX IX_Date_Quarter
    ON dw.DimDate (year_number, quarter_number)
    INCLUDE (month_number, full_date);
PRINT 'IX_Date_Quarter dibuat';

-- DimRoute
CREATE NONCLUSTERED INDEX IX_Route_Type
    ON dw.DimRoute (route_type, is_active)
    INCLUDE (origin_city, destination_city, distance_km);
PRINT 'IX_Route_Type dibuat';

-- DimPayment
CREATE NONCLUSTERED INDEX IX_Payment_Method
    ON dw.DimPayment (payment_method, payment_status)
    INCLUDE (payment_channel, is_cod);
PRINT 'IX_Payment_Method dibuat';

-- DimPackage
CREATE NONCLUSTERED INDEX IX_Package_WeightCategory
    ON dw.DimPackage (weight_category)
    INCLUDE (package_type, is_fragile, is_insured);
PRINT 'IX_Package_WeightCategory dibuat';

GO

-- ============================================================
-- VERIFIKASI: Tampilkan semua index yang berhasil dibuat
-- ============================================================
SELECT
    t.name          AS TableName,
    i.name          AS IndexName,
    i.type_desc     AS IndexType,
    i.is_unique     AS IsUnique
FROM sys.indexes i
JOIN sys.tables  t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('dw')
  AND i.type > 0   -- exclude heap
ORDER BY t.name, i.type_desc DESC, i.name;
GO

PRINT '================================================';
PRINT 'Semua index berhasil dibuat.';
PRINT 'Query performance siap untuk demo & Power BI.';
PRINT '================================================';
GO
