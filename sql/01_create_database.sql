-- ==============================================================================
-- File      : 01_create_database.sql
-- Tujuan    : Membuat database utama untuk Proyek Data Warehouse Logistik
-- ==============================================================================

-- 1. Membuat database jika belum ada
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'Logistics_DW')
BEGIN
    CREATE DATABASE Logistics_DW;
    PRINT 'Database Logistics_DW berhasil dibuat.';
END
ELSE
BEGIN
    PRINT 'Database Logistics_DW sudah ada, melanjutkan...';
END
GO

-- 2. Gunakan database ini untuk seluruh script selanjutnya
USE Logistics_DW;
GO

PRINT '================================================';
PRINT 'Database Logistics_DW siap digunakan.';
PRINT '================================================';
GO
