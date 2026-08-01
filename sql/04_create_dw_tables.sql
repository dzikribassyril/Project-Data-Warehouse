-- ==============================================================================
-- File      : 04_create_dw_tables.sql
-- Tujuan    : Membuat tabel Dimensi & Fakta (Star Schema) dengan constraint
-- ==============================================================================

USE Logistics_DW;
GO

-- ============================================================
-- 1. BUAT SCHEMA DW (jika belum ada)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dw')
BEGIN
    EXEC('CREATE SCHEMA dw');
    PRINT 'Schema [dw] berhasil dibuat.';
END
GO

-- ============================================================
-- 2. DROP TABEL LAMA (urutan: Fact dulu, baru Dim)
-- ============================================================
DROP TABLE IF EXISTS dw.FactDeliveryPerformance;
DROP TABLE IF EXISTS dw.DimDate;
DROP TABLE IF EXISTS dw.DimCustomer;
DROP TABLE IF EXISTS dw.DimBranch;
DROP TABLE IF EXISTS dw.DimCourier;
DROP TABLE IF EXISTS dw.DimService;
DROP TABLE IF EXISTS dw.DimPackage;
DROP TABLE IF EXISTS dw.DimShipmentStatus;
DROP TABLE IF EXISTS dw.DimRoute;
DROP TABLE IF EXISTS dw.DimPayment;
GO

-- ============================================================
-- 3. DIMENSION TABLES
-- ============================================================

-- DimDate: Role-playing dimension (dipakai 3x di Fact sebagai FK)
CREATE TABLE dw.DimDate (
    date_key        INT             NOT NULL,
    full_date       DATE            NOT NULL,
    day_number      INT             NOT NULL,
    day_name        VARCHAR(10)     NOT NULL,
    month_number    INT             NOT NULL,
    month_name      VARCHAR(15)     NOT NULL,
    quarter_number  INT             NOT NULL,
    year_number     INT             NOT NULL,
    is_weekend      BIT             NOT NULL,

    CONSTRAINT PK_DimDate PRIMARY KEY (date_key)
);

-- DimCustomer
CREATE TABLE dw.DimCustomer (
    customer_key        INT             NOT NULL,
    customer_id         VARCHAR(15)     NOT NULL,
    customer_name       VARCHAR(100)    NOT NULL,
    customer_type       VARCHAR(20)     NOT NULL,
    gender              VARCHAR(15)     NOT NULL,
    phone               VARCHAR(20)     NULL,     
    email               VARCHAR(100)    NULL,     
    city                VARCHAR(50)     NOT NULL,
    province            VARCHAR(50)     NOT NULL,
    registration_date   DATE            NOT NULL,
    is_active           BIT             NOT NULL,

    CONSTRAINT PK_DimCustomer  PRIMARY KEY (customer_key),
    CONSTRAINT UQ_DimCustomer_ID UNIQUE (customer_id)
);

-- DimBranch
CREATE TABLE dw.DimBranch (
    branch_key      INT             NOT NULL,
    branch_id       VARCHAR(15)     NOT NULL,
    branch_name     VARCHAR(50)     NOT NULL,
    branch_type     VARCHAR(15)     NOT NULL,
    address         VARCHAR(200)    NOT NULL,
    city            VARCHAR(50)     NOT NULL,
    province        VARCHAR(50)     NOT NULL,
    region          VARCHAR(30)     NOT NULL,
    manager_name    VARCHAR(100)    NOT NULL,
    opening_date    DATE            NOT NULL,
    is_active       BIT             NOT NULL,

    CONSTRAINT PK_DimBranch     PRIMARY KEY (branch_key),
    CONSTRAINT UQ_DimBranch_ID  UNIQUE (branch_id)
);

-- DimCourier
CREATE TABLE dw.DimCourier (
    courier_key     INT             NOT NULL,
    courier_id      VARCHAR(15)     NOT NULL,
    courier_name    VARCHAR(100)    NOT NULL,
    gender          VARCHAR(15)     NOT NULL,
    phone           VARCHAR(20)     NOT NULL,
    branch_id       VARCHAR(15)     NOT NULL,
    vehicle_type    VARCHAR(15)     NOT NULL,
    hire_date       DATE            NOT NULL,
    employee_status VARCHAR(15)     NOT NULL,
    is_active       BIT             NOT NULL,

    CONSTRAINT PK_DimCourier    PRIMARY KEY (courier_key),
    CONSTRAINT UQ_DimCourier_ID UNIQUE (courier_id)
);

-- DimService
CREATE TABLE dw.DimService (
    service_key             INT             NOT NULL,
    service_code            VARCHAR(5)      NOT NULL,
    service_name            VARCHAR(20)     NOT NULL,
    service_category        VARCHAR(15)     NOT NULL,
    delivery_estimation     VARCHAR(25)     NOT NULL,
    max_weight              DECIMAL(5,1)    NOT NULL,
    is_cod_available        BIT             NOT NULL,
    is_active               BIT             NOT NULL,

    CONSTRAINT PK_DimService    PRIMARY KEY (service_key),
    CONSTRAINT UQ_DimService_Code UNIQUE (service_code)
);

-- DimPackage
CREATE TABLE dw.DimPackage (
    package_key         INT             NOT NULL,
    package_id          VARCHAR(15)     NOT NULL,
    package_type        VARCHAR(15)     NOT NULL,
    package_category    VARCHAR(10)     NOT NULL,
    weight              DECIMAL(6,2)    NOT NULL,
    weight_category     VARCHAR(15)     NOT NULL,
    length_cm           INT             NOT NULL,
    width_cm            INT             NOT NULL,
    height_cm           INT             NOT NULL,
    volume_cm3          INT             NOT NULL,
    is_fragile          BIT             NOT NULL,
    is_insured          BIT             NOT NULL,
    item_description    VARCHAR(100)    NULL,    

    CONSTRAINT PK_DimPackage    PRIMARY KEY (package_key),
    CONSTRAINT UQ_DimPackage_ID UNIQUE (package_id)
);

-- DimShipmentStatus
CREATE TABLE dw.DimShipmentStatus (
    status_key          INT             NOT NULL,
    status_code         VARCHAR(15)     NOT NULL,
    status_name         VARCHAR(30)     NOT NULL,
    status_category     VARCHAR(15)     NOT NULL,
    status_description  VARCHAR(100)    NOT NULL,

    CONSTRAINT PK_DimShipmentStatus     PRIMARY KEY (status_key),
    CONSTRAINT UQ_DimShipmentStatus_Code UNIQUE (status_code)
);

-- DimRoute
CREATE TABLE dw.DimRoute (
    route_key               INT             NOT NULL,
    route_id                VARCHAR(10)     NOT NULL,
    origin_city             VARCHAR(50)     NOT NULL,
    destination_city        VARCHAR(50)     NOT NULL,
    origin_region           VARCHAR(30)     NOT NULL,
    destination_region      VARCHAR(30)     NOT NULL,
    distance_km             INT             NOT NULL,
    route_type              VARCHAR(35)     NOT NULL,
    is_active               BIT             NOT NULL,

    CONSTRAINT PK_DimRoute      PRIMARY KEY (route_key),
    CONSTRAINT UQ_DimRoute_ID   UNIQUE (route_id)
);

-- DimPayment
CREATE TABLE dw.DimPayment (
    payment_key     INT             NOT NULL,
    payment_id      VARCHAR(15)     NOT NULL,
    payment_method  VARCHAR(20)     NOT NULL,
    payment_channel VARCHAR(20)     NOT NULL,
    bank_name       VARCHAR(20)     NULL,     
    payment_date    DATE            NOT NULL,
    payment_status  VARCHAR(10)     NOT NULL,
    is_cod          BIT             NOT NULL,
    refund_status   VARCHAR(20)     NOT NULL,

    CONSTRAINT PK_DimPayment    PRIMARY KEY (payment_key),
    CONSTRAINT UQ_DimPayment_ID UNIQUE (payment_id)
);

-- ============================================================
-- 4. FACT TABLE
-- ============================================================
CREATE TABLE dw.FactDeliveryPerformance (
    -- Surrogate Key
    shipment_key    INT             NOT NULL,
    shipment_id     VARCHAR(15)     NOT NULL,
    awb_number      VARCHAR(25)     NOT NULL,

    -- Foreign Keys (Role-Playing: DimDate dipakai 3x)
    transaction_date_key    INT     NOT NULL,
    pickup_date_key         INT     NULL,  
    delivery_date_key       INT     NULL, 

    customer_key    INT     NOT NULL,
    branch_key      INT     NOT NULL,
    courier_key     INT     NOT NULL,
    service_key     INT     NOT NULL,
    package_key     INT     NOT NULL,
    status_key      INT     NOT NULL,
    route_key       INT     NOT NULL,
    payment_key     INT     NOT NULL,

    -- Measures
    total_shipment  INT             NOT NULL DEFAULT 1,
    estimated_days  INT             NOT NULL,
    actual_days     INT             NULL, 
    delay_days      INT             NULL,   
    package_weight  DECIMAL(6,2)   NOT NULL,
    shipping_fee    INT             NOT NULL,
    insurance_fee   INT             NOT NULL DEFAULT 0,
    discount_amount INT             NOT NULL DEFAULT 0,
    total_amount    INT             NOT NULL,

    -- Flags (pre-calculated untuk performa Power BI)
    is_delivered    BIT             NOT NULL DEFAULT 0,
    is_late         BIT             NOT NULL DEFAULT 0,
    is_failed       BIT             NOT NULL DEFAULT 0,
    is_returned     BIT             NOT NULL DEFAULT 0,
    is_cancelled    BIT             NOT NULL DEFAULT 0,

    -- Constraints
    CONSTRAINT PK_FactDelivery PRIMARY KEY (shipment_key),
    CONSTRAINT UQ_Fact_ShipmentID UNIQUE (shipment_id),
    CONSTRAINT UQ_Fact_AWB        UNIQUE (awb_number),

    CONSTRAINT FK_Fact_TransactionDate  FOREIGN KEY (transaction_date_key) REFERENCES dw.DimDate(date_key),
    CONSTRAINT FK_Fact_PickupDate       FOREIGN KEY (pickup_date_key)      REFERENCES dw.DimDate(date_key),
    CONSTRAINT FK_Fact_DeliveryDate     FOREIGN KEY (delivery_date_key)    REFERENCES dw.DimDate(date_key),
    CONSTRAINT FK_Fact_Customer         FOREIGN KEY (customer_key)         REFERENCES dw.DimCustomer(customer_key),
    CONSTRAINT FK_Fact_Branch           FOREIGN KEY (branch_key)           REFERENCES dw.DimBranch(branch_key),
    CONSTRAINT FK_Fact_Courier          FOREIGN KEY (courier_key)          REFERENCES dw.DimCourier(courier_key),
    CONSTRAINT FK_Fact_Service          FOREIGN KEY (service_key)          REFERENCES dw.DimService(service_key),
    CONSTRAINT FK_Fact_Package          FOREIGN KEY (package_key)          REFERENCES dw.DimPackage(package_key),
    CONSTRAINT FK_Fact_Status           FOREIGN KEY (status_key)           REFERENCES dw.DimShipmentStatus(status_key),
    CONSTRAINT FK_Fact_Route            FOREIGN KEY (route_key)            REFERENCES dw.DimRoute(route_key),
    CONSTRAINT FK_Fact_Payment          FOREIGN KEY (payment_key)          REFERENCES dw.DimPayment(payment_key)
);
GO

PRINT '================================================';
PRINT 'Star Schema (schema [dw]) berhasil dibuat:';
PRINT '  - 9 Dimension Tables';
PRINT '  - 1 Fact Table dengan 11 FK + UNIQUE constraints';
PRINT '================================================';
GO
