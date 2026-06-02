-- ==============================================================================
-- File      : 04_create_dw_tables.sql
-- Tujuan    : Membuat tabel Dimensi dan Fakta (Star Schema) dengan Constraint
-- ==============================================================================

USE Logistics_DW;
GO

-- 1. DROP TABLES IF THEY ALREADY EXIST

DROP TABLE IF EXISTS FactDeliveryPerformance;
DROP TABLE IF EXISTS DimDate;
DROP TABLE IF EXISTS DimCustomer;
DROP TABLE IF EXISTS DimBranch;
DROP TABLE IF EXISTS DimCourier;
DROP TABLE IF EXISTS DimService;
DROP TABLE IF EXISTS DimPackage;
DROP TABLE IF EXISTS DimShipmentStatus;
DROP TABLE IF EXISTS DimRoute;
DROP TABLE IF EXISTS DimPayment;
GO

-- 2. CREATE DIMENSION TABLES

CREATE TABLE DimDate (
    date_key INT PRIMARY KEY,
    full_date DATE,
    day_number INT,
    day_name VARCHAR(10),
    month_number INT,
    month_name VARCHAR(15),
    quarter_number INT,
    year_number INT,
    is_weekend BIT
);

CREATE TABLE DimCustomer (
    customer_key INT PRIMARY KEY,
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

CREATE TABLE DimBranch (
    branch_key INT PRIMARY KEY,
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

CREATE TABLE DimCourier (
    courier_key INT PRIMARY KEY,
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

CREATE TABLE DimService (
    service_key INT PRIMARY KEY,
    service_code VARCHAR(5),
    service_name VARCHAR(20),
    service_category VARCHAR(15),
    delivery_estimation VARCHAR(20),
    max_weight DECIMAL(5,1),
    is_cod_available BIT,
    is_active BIT
);

CREATE TABLE DimPackage (
    package_key INT PRIMARY KEY,
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

CREATE TABLE DimShipmentStatus (
    status_key INT PRIMARY KEY,
    status_code VARCHAR(15),
    status_name VARCHAR(30),
    status_category VARCHAR(10),
    status_description VARCHAR(100)
);

CREATE TABLE DimRoute (
    route_key INT PRIMARY KEY,
    route_id VARCHAR(10),
    origin_city VARCHAR(50),
    destination_city VARCHAR(50),
    origin_region VARCHAR(30),
    destination_region VARCHAR(30),
    distance_km INT,
    route_type VARCHAR(30),
    is_active BIT
);

CREATE TABLE DimPayment (
    payment_key INT PRIMARY KEY,
    payment_id VARCHAR(12),
    payment_method VARCHAR(20),
    payment_channel VARCHAR(20),
    bank_name VARCHAR(20),
    payment_date DATE,
    payment_status VARCHAR(10),
    is_cod BIT,
    refund_status VARCHAR(20)
);

-- 3. CREATE FACT TABLE

CREATE TABLE FactDeliveryPerformance (
    shipment_key INT PRIMARY KEY,
    shipment_id VARCHAR(12),
    awb_number VARCHAR(20),
    
    -- Foreign Keys
    transaction_date_key INT FOREIGN KEY REFERENCES DimDate(date_key),
    pickup_date_key INT FOREIGN KEY REFERENCES DimDate(date_key),
    delivery_date_key INT FOREIGN KEY REFERENCES DimDate(date_key),
    customer_key INT FOREIGN KEY REFERENCES DimCustomer(customer_key),
    branch_key INT FOREIGN KEY REFERENCES DimBranch(branch_key),
    courier_key INT FOREIGN KEY REFERENCES DimCourier(courier_key),
    service_key INT FOREIGN KEY REFERENCES DimService(service_key),
    package_key INT FOREIGN KEY REFERENCES DimPackage(package_key),
    status_key INT FOREIGN KEY REFERENCES DimShipmentStatus(status_key),
    route_key INT FOREIGN KEY REFERENCES DimRoute(route_key),
    payment_key INT FOREIGN KEY REFERENCES DimPayment(payment_key),
    
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