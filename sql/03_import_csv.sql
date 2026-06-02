-- ==============================================================================
-- File      : 03_import_csv.sql
-- Tujuan    : Memasukkan data dari file CSV mentah ke tabel Staging Area
-- ==============================================================================

USE Logistics_DW;
GO

-- 1. Import stg_DimDate
BULK INSERT stg_DimDate
FROM 'D:\Arsip Hafizh Fadhl Muhammad\Project\Project-Data-Warehouse\csv\DimDate.csv'
WITH ( FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n' );
GO

-- 2. Import stg_DimCustomer
BULK INSERT stg_DimCustomer
FROM 'D:\Arsip Hafizh Fadhl Muhammad\Project\Project-Data-Warehouse\csv\DimCustomer.csv'
WITH ( FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n' );
GO

-- 3. Import stg_DimBranch
BULK INSERT stg_DimBranch
FROM 'D:\Arsip Hafizh Fadhl Muhammad\Project\Project-Data-Warehouse\csv\DimBranch.csv'
WITH ( FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n' );
GO

-- 4. Import stg_DimCourier
BULK INSERT stg_DimCourier
FROM 'D:\Arsip Hafizh Fadhl Muhammad\Project\Project-Data-Warehouse\csv\DimCourier.csv'
WITH ( FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n' );
GO

-- 5. Import stg_DimService
BULK INSERT stg_DimService
FROM 'D:\Arsip Hafizh Fadhl Muhammad\Project\Project-Data-Warehouse\csv\DimService.csv'
WITH ( FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n' );
GO

-- 6. Import stg_DimPackage
BULK INSERT stg_DimPackage
FROM 'D:\Arsip Hafizh Fadhl Muhammad\Project\Project-Data-Warehouse\csv\DimPackage.csv'
WITH ( FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n' );
GO

-- 7. Import stg_DimShipmentStatus
BULK INSERT stg_DimShipmentStatus
FROM 'D:\Arsip Hafizh Fadhl Muhammad\Project\Project-Data-Warehouse\csv\DimShipmentStatus.csv'
WITH ( FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n' );
GO

-- 8. Import stg_DimRoute
BULK INSERT stg_DimRoute
FROM 'D:\Arsip Hafizh Fadhl Muhammad\Project\Project-Data-Warehouse\csv\DimRoute.csv'
WITH ( FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n' );
GO

-- 9. Import stg_DimPayment
BULK INSERT stg_DimPayment
FROM 'D:\Arsip Hafizh Fadhl Muhammad\Project\Project-Data-Warehouse\csv\DimPayment.csv'
WITH ( FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n' );
GO

-- 10. Import stg_FactDeliveryPerformance
BULK INSERT stg_FactDeliveryPerformance
FROM 'D:\Arsip Hafizh Fadhl Muhammad\Project\Project-Data-Warehouse\csv\FactDeliveryPerformance.csv'
WITH ( FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n' );
GO