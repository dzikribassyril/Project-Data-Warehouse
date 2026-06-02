-- ==============================================================================
-- File      : 02_create_staging_tables.sql
-- Tujuan    : Membuat tabel (Staging Area) untuk raw CSV data
-- ==============================================================================

USE Logistics_DW;
GO

-- 1. Membersihkan tabel jika sebelumnya sudah ada
DROP TABLE IF EXISTS stg_DimDate;
DROP TABLE IF EXISTS stg_DimCustomer;
DROP TABLE IF EXISTS stg_DimBranch;
DROP TABLE IF EXISTS stg_DimCourier;
DROP TABLE IF EXISTS stg_DimService;
DROP TABLE IF EXISTS stg_DimPackage;
DROP TABLE IF EXISTS stg_DimShipmentStatus;
DROP TABLE IF EXISTS stg_DimRoute;
DROP TABLE IF EXISTS stg_DimPayment;
DROP TABLE IF EXISTS stg_FactDeliveryPerformance;
GO

-- 2. Membuat tabel staging

CREATE TABLE stg_DimDate (
    date_key INT,
    full_date DATE,
    day_number INT,
    day_name VARCHAR(10),
    month_number INT,
    month_name VARCHAR(15),
    quarter_number INT,
    year_number INT,
    is_weekend BIT
);

CREATE TABLE stg_DimCustomer (
    customer_key INT,
    customer_id VARCHAR(10),
    customer_name VARCHAR(100),
    customer_type VARCHAR(20),
    gender VARCHAR(15),
    phone VARCHAR(15),
    email VARCHAR(100),
    city VARCHAR(50),
    province VARCHAR(50),
    registration_date DATE,
    is_active BIT
);

CREATE TABLE stg_DimBranch (
    branch_key INT,
    branch_id VARCHAR(10),
    branch_name VARCHAR(50),
    branch_type VARCHAR(15),
    address VARCHAR(200),
    city VARCHAR(50),
    province VARCHAR(50),
    region VARCHAR(30),
    manager_name VARCHAR(100),
    opening_date DATE,
    is_active BIT
);

CREATE TABLE stg_DimCourier (
    courier_key INT,
    courier_id VARCHAR(10),
    courier_name VARCHAR(100),
    gender VARCHAR(15),
    phone VARCHAR(15),
    branch_id VARCHAR(10),
    vehicle_type VARCHAR(15),
    hire_date DATE,
    employee_status VARCHAR(15),
    is_active BIT
);

CREATE TABLE stg_DimService (
    service_key INT,
    service_code VARCHAR(5),
    service_name VARCHAR(20),
    service_category VARCHAR(15),
    delivery_estimation VARCHAR(20),
    max_weight DECIMAL(5,1),
    is_cod_available BIT,
    is_active BIT
);

CREATE TABLE stg_DimPackage (
    package_key INT,
    package_id VARCHAR(12),
    package_type VARCHAR(15),
    package_category VARCHAR(10),
    weight DECIMAL(6,2),
    weight_category VARCHAR(15),
    length_cm INT,
    width_cm INT,
    height_cm INT,
    volume_cm3 INT,
    is_fragile BIT,
    is_insured BIT,
    item_description VARCHAR(100)
);

CREATE TABLE stg_DimShipmentStatus (
    status_key INT,
    status_code VARCHAR(15),
    status_name VARCHAR(30),
    status_category VARCHAR(10),
    status_description VARCHAR(100)
);

CREATE TABLE stg_DimRoute (
    route_key INT,
    route_id VARCHAR(10),
    origin_city VARCHAR(50),
    destination_city VARCHAR(50),
    origin_region VARCHAR(30),
    destination_region VARCHAR(30),
    distance_km INT,
    route_type VARCHAR(30),
    is_active BIT
);

CREATE TABLE stg_DimPayment (
    payment_key INT,
    payment_id VARCHAR(12),
    payment_method VARCHAR(20),
    payment_channel VARCHAR(20),
    bank_name VARCHAR(20),
    payment_date DATE,
    payment_status VARCHAR(10),
    is_cod BIT,
    refund_status VARCHAR(20)
);

CREATE TABLE stg_FactDeliveryPerformance (
    -- Foreign Keys & IDs
    shipment_key INT,
    shipment_id VARCHAR(12),
    awb_number VARCHAR(20),
    transaction_date_key INT,
    pickup_date_key INT,
    delivery_date_key INT,
    customer_key INT,
    branch_key INT,
    courier_key INT,
    service_key INT,
    package_key INT,
    status_key INT,
    route_key INT,
    payment_key INT,
    -- Measures
    total_shipment INT,
    estimated_days INT,
    actual_days INT,
    delay_days INT,
    package_weight DECIMAL(6,2),
    shipping_fee INT,
    insurance_fee INT,
    discount_amount INT,
    total_amount INT,
    -- Flags
    is_delivered BIT,
    is_late BIT,
    is_failed BIT,
    is_returned BIT,
    is_cancelled BIT
);
GO