-- ==============================================================================
-- File      : 01_create_database.sql
-- Tujuan    : Membuat database utama untuk Proyek Data Warehouse Logistik
-- ==============================================================================

-- 1. Mengecek dan membuat database jika belum ada
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'Logistics_DW')
BEGIN
    CREATE DATABASE Logistics_DW;
END
GO

-- 2. Memastikan seluruh eksekusi script selanjutnya menggunakan database ini
USE Logistics_DW;
GO