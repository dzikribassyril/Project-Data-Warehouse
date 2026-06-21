-- ==============================================================================
-- File      : 02_create_staging_tables.sql
-- Tujuan    : Membuat Staging Area untuk menampung raw data CSV sebelum ETL
-- Catatan   : Staging menggunakan semua kolom VARCHAR agar BULK INSERT tidak
--             gagal karena type mismatch — konversi tipe dilakukan di step 05/06
-- ==============================================================================

USE Logistics_DW;
GO

-- ============================================================
-- 1. BUAT SCHEMA STAGING (jika belum ada)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg')
BEGIN
    EXEC('CREATE SCHEMA stg');
    PRINT 'Schema [stg] berhasil dibuat.';
END
GO

-- ============================================================
-- 2. DROP & RECREATE TABEL STAGING
--    Idempotent: aman dijalankan berulang kali
-- ============================================================
DROP TABLE IF EXISTS stg.DimDate;
DROP TABLE IF EXISTS stg.DimCustomer;
DROP TABLE IF EXISTS stg.DimBranch;
DROP TABLE IF EXISTS stg.DimCourier;
DROP TABLE IF EXISTS stg.DimService;
DROP TABLE IF EXISTS stg.DimPackage;
DROP TABLE IF EXISTS stg.DimShipmentStatus;
DROP TABLE IF EXISTS stg.DimRoute;
DROP TABLE IF EXISTS stg.DimPayment;
DROP TABLE IF EXISTS stg.FactDeliveryPerformance;
GO

-- ============================================================
-- 3. CREATE STAGING TABLES
--    Semua kolom VARCHAR — konversi dilakukan di transform step
-- ============================================================

CREATE TABLE stg.DimDate (
    date_key        VARCHAR(10),
    full_date       VARCHAR(20),
    day_number      VARCHAR(5),
    day_name        VARCHAR(15),
    month_number    VARCHAR(5),
    month_name      VARCHAR(20),
    quarter_number  VARCHAR(5),
    year_number     VARCHAR(10),
    is_weekend      VARCHAR(5)
);

CREATE TABLE stg.DimCustomer (
    customer_key        VARCHAR(10),
    customer_id         VARCHAR(15),
    customer_name       VARCHAR(100),
    customer_type       VARCHAR(20),
    gender              VARCHAR(15),
    phone               VARCHAR(20),
    email               VARCHAR(100),
    city                VARCHAR(50),
    province            VARCHAR(50),
    registration_date   VARCHAR(20),
    is_active           VARCHAR(5)
);

CREATE TABLE stg.DimBranch (
    branch_key      VARCHAR(10),
    branch_id       VARCHAR(15),
    branch_name     VARCHAR(50),
    branch_type     VARCHAR(15),
    address         VARCHAR(200),
    city            VARCHAR(50),
    province        VARCHAR(50),
    region          VARCHAR(30),
    manager_name    VARCHAR(100),
    opening_date    VARCHAR(20),
    is_active       VARCHAR(5)
);

CREATE TABLE stg.DimCourier (
    courier_key     VARCHAR(10),
    courier_id      VARCHAR(15),
    courier_name    VARCHAR(100),
    gender          VARCHAR(15),
    phone           VARCHAR(20),
    branch_id       VARCHAR(15),
    vehicle_type    VARCHAR(15),
    hire_date       VARCHAR(20),
    employee_status VARCHAR(15),
    is_active       VARCHAR(5)
);

CREATE TABLE stg.DimService (
    service_key             VARCHAR(5),
    service_code            VARCHAR(5),
    service_name            VARCHAR(20),
    service_category        VARCHAR(15),
    delivery_estimation     VARCHAR(25),
    max_weight              VARCHAR(10),
    is_cod_available        VARCHAR(5),
    is_active               VARCHAR(5)
);

CREATE TABLE stg.DimPackage (
    package_key         VARCHAR(10),
    package_id          VARCHAR(15),
    package_type        VARCHAR(15),
    package_category    VARCHAR(10),
    weight              VARCHAR(10),
    weight_category     VARCHAR(15),
    length_cm           VARCHAR(10),
    width_cm            VARCHAR(10),
    height_cm           VARCHAR(10),
    volume_cm3          VARCHAR(15),
    is_fragile          VARCHAR(5),
    is_insured          VARCHAR(5),
    item_description    VARCHAR(100)
);

CREATE TABLE stg.DimShipmentStatus (
    status_key          VARCHAR(5),
    status_code         VARCHAR(15),
    status_name         VARCHAR(30),
    status_category     VARCHAR(15),
    status_description  VARCHAR(100)
);

CREATE TABLE stg.DimRoute (
    route_key               VARCHAR(10),
    route_id                VARCHAR(10),
    origin_city             VARCHAR(50),
    destination_city        VARCHAR(50),
    origin_region           VARCHAR(30),
    destination_region      VARCHAR(30),
    distance_km             VARCHAR(10),
    route_type              VARCHAR(35),
    is_active               VARCHAR(5)
);

CREATE TABLE stg.DimPayment (
    payment_key     VARCHAR(10),
    payment_id      VARCHAR(15),
    payment_method  VARCHAR(20),
    payment_channel VARCHAR(20),
    bank_name       VARCHAR(20),
    payment_date    VARCHAR(20),
    payment_status  VARCHAR(10),
    is_cod          VARCHAR(5),
    refund_status   VARCHAR(20)
);

CREATE TABLE stg.FactDeliveryPerformance (
    shipment_key            VARCHAR(10),
    shipment_id             VARCHAR(15),
    awb_number              VARCHAR(25),
    transaction_date_key    VARCHAR(10),
    pickup_date_key         VARCHAR(10),
    delivery_date_key       VARCHAR(10),
    customer_key            VARCHAR(10),
    branch_key              VARCHAR(10),
    courier_key             VARCHAR(10),
    service_key             VARCHAR(5),
    package_key             VARCHAR(10),
    status_key              VARCHAR(5),
    route_key               VARCHAR(10),
    payment_key             VARCHAR(10),
    total_shipment          VARCHAR(5),
    estimated_days          VARCHAR(5),
    actual_days             VARCHAR(5),
    delay_days              VARCHAR(5),
    package_weight          VARCHAR(10),
    shipping_fee            VARCHAR(15),
    insurance_fee           VARCHAR(15),
    discount_amount         VARCHAR(15),
    total_amount            VARCHAR(15),
    is_delivered            VARCHAR(5),
    is_late                 VARCHAR(5),
    is_failed               VARCHAR(5),
    is_returned             VARCHAR(5),
    is_cancelled            VARCHAR(5)
);
GO

PRINT '================================================';
PRINT 'Semua tabel staging berhasil dibuat di schema [stg].';
PRINT '================================================';
GO
