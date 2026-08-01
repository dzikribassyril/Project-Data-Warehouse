USE Logistics_DW;
GO

-- ============================================================
-- KONFIGURASI PATH
-- ============================================================
DECLARE @BasePath NVARCHAR(500) =
N'D:\Arsip Hafizh Fadhl Muhammad\Project\Project-Data-Warehouse\dataset\';

DECLARE @SQL NVARCHAR(MAX);
DECLARE @RowCount INT;

-- ============================================================
-- 1. TRUNCATE STAGING
-- ============================================================
TRUNCATE TABLE stg.DimDate;
TRUNCATE TABLE stg.DimCustomer;
TRUNCATE TABLE stg.DimBranch;
TRUNCATE TABLE stg.DimCourier;
TRUNCATE TABLE stg.DimService;
TRUNCATE TABLE stg.DimPackage;
TRUNCATE TABLE stg.DimShipmentStatus;
TRUNCATE TABLE stg.DimRoute;
TRUNCATE TABLE stg.DimPayment;
TRUNCATE TABLE stg.FactDeliveryPerformance;

PRINT 'Staging tables berhasil di-truncate.';

-- ============================================================
-- 2. IMPORT DimDate
-- ============================================================
SET @SQL = N'
BULK INSERT stg.DimDate
FROM ''' + @BasePath + N'DimDate.csv''
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);';

EXEC sp_executesql @SQL;

SELECT @RowCount = COUNT(*) FROM stg.DimDate;
PRINT CONCAT('1/10 - stg.DimDate : ', @RowCount, ' baris');

-- ============================================================
-- 3. IMPORT DimCustomer
-- ============================================================
SET @SQL = N'
BULK INSERT stg.DimCustomer
FROM ''' + @BasePath + N'DimCustomer.csv''
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);';

EXEC sp_executesql @SQL;

SELECT @RowCount = COUNT(*) FROM stg.DimCustomer;
PRINT CONCAT('2/10 - stg.DimCustomer : ', @RowCount, ' baris');

-- ============================================================
-- 4. IMPORT DimBranch
-- ============================================================
SET @SQL = N'
BULK INSERT stg.DimBranch
FROM ''' + @BasePath + N'DimBranch.csv''
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);';

EXEC sp_executesql @SQL;

SELECT @RowCount = COUNT(*) FROM stg.DimBranch;
PRINT CONCAT('3/10 - stg.DimBranch : ', @RowCount, ' baris');

-- ============================================================
-- 5. IMPORT DimCourier
-- ============================================================
SET @SQL = N'
BULK INSERT stg.DimCourier
FROM ''' + @BasePath + N'DimCourier.csv''
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);';

EXEC sp_executesql @SQL;

SELECT @RowCount = COUNT(*) FROM stg.DimCourier;
PRINT CONCAT('4/10 - stg.DimCourier : ', @RowCount, ' baris');

-- ============================================================
-- 6. IMPORT DimService
-- ============================================================
SET @SQL = N'
BULK INSERT stg.DimService
FROM ''' + @BasePath + N'DimService.csv''
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);';

EXEC sp_executesql @SQL;

SELECT @RowCount = COUNT(*) FROM stg.DimService;
PRINT CONCAT('5/10 - stg.DimService : ', @RowCount, ' baris');

-- ============================================================
-- 7. IMPORT DimPackage
-- ============================================================
SET @SQL = N'
BULK INSERT stg.DimPackage
FROM ''' + @BasePath + N'DimPackage.csv''
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);';

EXEC sp_executesql @SQL;

SELECT @RowCount = COUNT(*) FROM stg.DimPackage;
PRINT CONCAT('6/10 - stg.DimPackage : ', @RowCount, ' baris');

-- ============================================================
-- 8. IMPORT DimShipmentStatus
-- ============================================================
SET @SQL = N'
BULK INSERT stg.DimShipmentStatus
FROM ''' + @BasePath + N'DimShipmentStatus.csv''
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);';

EXEC sp_executesql @SQL;

SELECT @RowCount = COUNT(*) FROM stg.DimShipmentStatus;
PRINT CONCAT('7/10 - stg.DimShipmentStatus : ', @RowCount, ' baris');

-- ============================================================
-- 9. IMPORT DimRoute
-- ============================================================
SET @SQL = N'
BULK INSERT stg.DimRoute
FROM ''' + @BasePath + N'DimRoute.csv''
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);';

EXEC sp_executesql @SQL;

SELECT @RowCount = COUNT(*) FROM stg.DimRoute;
PRINT CONCAT('8/10 - stg.DimRoute : ', @RowCount, ' baris');

-- ============================================================
-- 10. IMPORT DimPayment
-- ============================================================
SET @SQL = N'
BULK INSERT stg.DimPayment
FROM ''' + @BasePath + N'DimPayment.csv''
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    TABLOCK
);';

EXEC sp_executesql @SQL;

SELECT @RowCount = COUNT(*) FROM stg.DimPayment;
PRINT CONCAT('9/10 - stg.DimPayment : ', @RowCount, ' baris');

-- ============================================================
-- 11. IMPORT FactDeliveryPerformance
-- ============================================================
SET @SQL = N'
BULK INSERT stg.FactDeliveryPerformance
FROM ''' + @BasePath + N'FactDeliveryPerformance.csv''
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''\n'',
    TABLOCK,
    BATCHSIZE = 10000
);';

EXEC sp_executesql @SQL;

SELECT @RowCount = COUNT(*)
FROM stg.FactDeliveryPerformance;

PRINT CONCAT('10/10 - stg.FactDeliveryPerformance : ', @RowCount, ' baris');

PRINT '================================================';
PRINT 'Import CSV ke Staging selesai.';
PRINT '================================================';
GO