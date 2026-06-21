@echo off
setlocal EnableDelayedExpansion

:: ==============================================================================
:: run_etl.bat
:: Tujuan  : Menjalankan seluruh pipeline ETL Data Warehouse Logistik secara
::           otomatis menggunakan SQLCMD
:: Cara    : Double-click file ini, atau jalankan dari Command Prompt
:: ==============================================================================

:: ============================================================
:: KONFIGURASI — Sesuaikan bagian ini dengan environment kamu
:: ============================================================
set SERVER=localhost\SQLEXPRESS
set DATABASE=Logistics_DW
:: Windows Authentication — tidak perlu USERNAME dan PASSWORD

:: Path ke folder project (tanpa trailing backslash)
set PROJECT_DIR=D:\Arsip Hafizh Fadhl Muhammad\Project\Project-Data-Warehouse

:: Path ke folder SQL scripts
set SQL_DIR=%PROJECT_DIR%\sql

:: Path ke folder logs (akan dibuat otomatis jika belum ada)
set LOG_DIR=%PROJECT_DIR%\logs

:: ============================================================
:: SETUP: Buat folder logs jika belum ada
:: ============================================================
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: Format timestamp untuk nama log file
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do set DATE_STR=%%c%%b%%a
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set TIME_STR=%%a%%b
set TIMESTAMP=%DATE_STR%_%TIME_STR%
set LOG_FILE=%LOG_DIR%\etl_%TIMESTAMP%.log

:: ============================================================
:: HEADER
:: ============================================================
cls
echo ================================================
echo   ETL Pipeline - Data Warehouse Logistik
echo   Mulai  : %date% %time%
echo   Server : %SERVER%
echo   DB     : %DATABASE%
echo   Log    : %LOG_FILE%
echo ================================================
echo.

:: Tulis header ke log file
echo ================================================ >> "%LOG_FILE%"
echo   ETL Pipeline - Data Warehouse Logistik        >> "%LOG_FILE%"
echo   Mulai  : %date% %time%                        >> "%LOG_FILE%"
echo   Server : %SERVER%                             >> "%LOG_FILE%"
echo   DB     : %DATABASE%                           >> "%LOG_FILE%"
echo ================================================ >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

:: ============================================================
:: CEK SQLCMD TERSEDIA
:: ============================================================
where sqlcmd >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] sqlcmd tidak ditemukan!
    echo         Pastikan SQL Server sudah terinstall dan sqlcmd ada di PATH.
    echo [ERROR] sqlcmd tidak ditemukan! >> "%LOG_FILE%"
    pause
    exit /b 1
)
echo [OK] sqlcmd ditemukan.
echo [OK] sqlcmd ditemukan. >> "%LOG_FILE%"
echo.

:: ============================================================
:: CEK KONEKSI KE SQL SERVER
:: ============================================================
echo [INFO] Mengecek koneksi ke SQL Server...
sqlcmd -S %SERVER% -E -Q "SELECT 'Koneksi OK' AS Status" -b >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Tidak bisa konek ke SQL Server!
    echo         Cek nama SERVER di bagian konfigurasi .bat ini.
    echo [ERROR] Koneksi SQL Server gagal! >> "%LOG_FILE%"
    pause
    exit /b 1
)
echo [OK] Koneksi ke SQL Server berhasil.
echo [OK] Koneksi ke SQL Server berhasil. >> "%LOG_FILE%"
echo.

:: ============================================================
:: FUNGSI JALANKAN SQL (via label + goto)
:: ============================================================

:: --------------------------------------------------
:: STEP 1: Create Database
:: --------------------------------------------------
echo [STEP 1/9] Membuat database...
echo [STEP 1/9] Create Database >> "%LOG_FILE%"

sqlcmd -S %SERVER% -E ^
    -i "%SQL_DIR%\01_create_database.sql" ^
    -b >> "%LOG_FILE%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :print_error "STEP 1 - Create Database"
    goto :end_with_error
)
echo [OK] STEP 1 selesai.
echo [OK] STEP 1 selesai. >> "%LOG_FILE%"
echo.

:: --------------------------------------------------
:: STEP 2: Create Staging Tables
:: --------------------------------------------------
echo [STEP 2/9] Membuat tabel staging...
echo [STEP 2/9] Create Staging Tables >> "%LOG_FILE%"

sqlcmd -S %SERVER% -E -d %DATABASE% ^
    -i "%SQL_DIR%\02_create_staging_tables.sql" ^
    -b >> "%LOG_FILE%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :print_error "STEP 2 - Create Staging Tables"
    goto :end_with_error
)
echo [OK] STEP 2 selesai.
echo [OK] STEP 2 selesai. >> "%LOG_FILE%"
echo.

:: --------------------------------------------------
:: STEP 3: Import CSV ke Staging
:: --------------------------------------------------
echo [STEP 3/9] Import CSV ke staging ^(proses terlama^)...
echo [STEP 3/9] Import CSV >> "%LOG_FILE%"

sqlcmd -S %SERVER% -E -d %DATABASE% ^
    -i "%SQL_DIR%\03_import_csv.sql" ^
    -b >> "%LOG_FILE%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :print_error "STEP 3 - Import CSV"
    goto :end_with_error
)
echo [OK] STEP 3 selesai.
echo [OK] STEP 3 selesai. >> "%LOG_FILE%"
echo.

:: --------------------------------------------------
:: STEP 4: Create DW Tables
:: --------------------------------------------------
echo [STEP 4/9] Membuat tabel dimensi dan fakta...
echo [STEP 4/9] Create DW Tables >> "%LOG_FILE%"

sqlcmd -S %SERVER% -E -d %DATABASE% ^
    -i "%SQL_DIR%\04_create_dw_tables.sql" ^
    -b >> "%LOG_FILE%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :print_error "STEP 4 - Create DW Tables"
    goto :end_with_error
)
echo [OK] STEP 4 selesai.
echo [OK] STEP 4 selesai. >> "%LOG_FILE%"
echo.

:: --------------------------------------------------
:: STEP 5: Transform & Load Dimensions
:: --------------------------------------------------
echo [STEP 5/9] Transform dan load dimensi...
echo [STEP 5/9] Load Dimensions >> "%LOG_FILE%"

sqlcmd -S %SERVER% -E -d %DATABASE% ^
    -i "%SQL_DIR%\05_transform_and_load_dimensions.sql" ^
    -b >> "%LOG_FILE%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :print_error "STEP 5 - Load Dimensions"
    goto :end_with_error
)
echo [OK] STEP 5 selesai.
echo [OK] STEP 5 selesai. >> "%LOG_FILE%"
echo.

:: --------------------------------------------------
:: STEP 6: Transform & Load Fact
:: --------------------------------------------------
echo [STEP 6/9] Transform dan load fact table...
echo [STEP 6/9] Load Fact >> "%LOG_FILE%"

sqlcmd -S %SERVER% -E -d %DATABASE% ^
    -i "%SQL_DIR%\06_transform_and_load_fact.sql" ^
    -b >> "%LOG_FILE%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :print_error "STEP 6 - Load Fact"
    goto :end_with_error
)
echo [OK] STEP 6 selesai.
echo [OK] STEP 6 selesai. >> "%LOG_FILE%"
echo.

:: --------------------------------------------------
:: STEP 7: Quality Check
:: --------------------------------------------------
echo [STEP 7/9] Menjalankan QA check...
echo [STEP 7/9] QA Check >> "%LOG_FILE%"

sqlcmd -S %SERVER% -E -d %DATABASE% ^
    -i "%SQL_DIR%\07_check_etl_result.sql" ^
    -b >> "%LOG_FILE%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :print_error "STEP 7 - QA Check"
    goto :end_with_error
)
echo [OK] STEP 7 selesai.
echo [OK] STEP 7 selesai. >> "%LOG_FILE%"
echo.

:: --------------------------------------------------
:: STEP 8: Create Indexes
:: --------------------------------------------------
echo [STEP 8/9] Membuat indexes...
echo [STEP 8/9] Create Indexes >> "%LOG_FILE%"

sqlcmd -S %SERVER% -E -d %DATABASE% ^
    -i "%SQL_DIR%\08_create_indexes.sql" ^
    -b >> "%LOG_FILE%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :print_error "STEP 8 - Create Indexes"
    goto :end_with_error
)
echo [OK] STEP 8 selesai.
echo [OK] STEP 8 selesai. >> "%LOG_FILE%"
echo.

:: --------------------------------------------------
:: STEP 9: Create Views
:: --------------------------------------------------
echo [STEP 9/9] Membuat analytical views...
echo [STEP 9/9] Create Views >> "%LOG_FILE%"

sqlcmd -S %SERVER% -E -d %DATABASE% ^
    -i "%SQL_DIR%\09_create_views.sql" ^
    -b >> "%LOG_FILE%" 2>&1

if %ERRORLEVEL% NEQ 0 (
    call :print_error "STEP 9 - Create Views"
    goto :end_with_error
)
echo [OK] STEP 9 selesai.
echo [OK] STEP 9 selesai. >> "%LOG_FILE%"
echo.

:: ============================================================
:: SUKSES
:: ============================================================
echo ================================================
echo   ETL PIPELINE SELESAI SUKSES!
echo   Selesai : %date% %time%
echo   Log     : %LOG_FILE%
echo ================================================
echo   Langkah selanjutnya:
echo   1. Buka SSMS untuk verifikasi data
echo   2. Connect Power BI ke views di schema [dw]
echo ================================================

echo. >> "%LOG_FILE%"
echo ================================================ >> "%LOG_FILE%"
echo   ETL PIPELINE SELESAI SUKSES!                  >> "%LOG_FILE%"
echo   Selesai : %date% %time%                        >> "%LOG_FILE%"
echo ================================================ >> "%LOG_FILE%"

pause
exit /b 0

:: ============================================================
:: LABEL: Error handler
:: ============================================================
:print_error
echo.
echo ================================================
echo   [GAGAL] %~1
echo   Cek log untuk detail: %LOG_FILE%
echo ================================================
echo.
echo [GAGAL] %~1 >> "%LOG_FILE%"
goto :eof

:end_with_error
echo.
echo Pipeline berhenti karena error.
echo Buka log file untuk detail: %LOG_FILE%
echo.
pause
exit /b 1