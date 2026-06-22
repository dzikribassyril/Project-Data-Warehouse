import os
import random
import time
import pandas as pd
from datetime import datetime, timedelta
from faker import Faker

fake = Faker('id_ID')

os.makedirs('../dataset', exist_ok=True)

MODE = 'DEMO'

if MODE == 'SMALL':
    NUM_TRANSACTIONS = 350
    NUM_CUSTOMERS    = 75
    NUM_COURIERS     = 25
    NUM_BRANCHES     = 13
    NUM_ROUTES       = 20
else:
    NUM_TRANSACTIONS = 100_000
    NUM_CUSTOMERS    = 5_000
    NUM_COURIERS     = 150
    NUM_BRANCHES     = 20
    NUM_ROUTES       = 30

HARI  = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu']
BULAN = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
         'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember']

BRANCH_CITIES = [
    ('Jakarta Pusat',   'DKI Jakarta',       'Jabodetabek'),
    ('Jakarta Selatan', 'DKI Jakarta',       'Jabodetabek'),
    ('Bandung',         'Jawa Barat',        'Jawa'),
    ('Surabaya',        'Jawa Timur',        'Jawa'),
    ('Medan',           'Sumatera Utara',    'Sumatera'),
    ('Makassar',        'Sulawesi Selatan',  'Sulawesi'),
    ('Palembang',       'Sumatera Selatan',  'Sumatera'),
    ('Solo',            'Jawa Tengah',       'Jawa'),
    ('Tangerang',       'Banten',            'Jabodetabek'),
    ('Bekasi',          'Jawa Barat',        'Jabodetabek'),
    ('Malang',          'Jawa Timur',        'Jawa'),
    ('Semarang',        'Jawa Tengah',       'Jawa'),
    ('Yogyakarta',      'DI Yogyakarta',     'Jawa'),
    ('Denpasar',        'Bali',              'Bali & Nusa Tenggara'),
    ('Balikpapan',      'Kalimantan Timur',  'Kalimantan'),
    ('Banjarmasin',     'Kalimantan Selatan','Kalimantan'),
    ('Manado',          'Sulawesi Utara',    'Sulawesi'),
    ('Padang',          'Sumatera Barat',    'Sumatera'),
    ('Pekanbaru',       'Riau',              'Sumatera'),
    ('Batam',           'Kepulauan Riau',    'Sumatera'),
]
BRANCH_CITIES = BRANCH_CITIES[:NUM_BRANCHES]

EWALLET_CHANNELS = ['GoPay', 'OVO', 'Dana', 'ShopeePay', 'LinkAja']
GENDERS          = ['Laki-laki', 'Perempuan']
CUSTOMER_TYPES   = ['Individual', 'Bisnis', 'Korporat']
PAYMENT_METHODS  = ['Transfer Bank', 'E-Wallet', 'COD']
BANKS            = ['BCA', 'Mandiri', 'BNI', 'BRI']
ITEM_DESCRIPTIONS = [
    'Elektronik - Smartphone', 'Pakaian - Kemeja', 'Dokumen Penting',
    'Alat Tulis Kantor', 'Aksesoris Komputer', 'Makanan Kering',
    'Obat-obatan', 'Kosmetik', 'Mainan Anak', 'Sepatu Olahraga',
    'Buku Pelajaran', 'Suku Cadang Motor', None
]

print(f"Mode: {MODE} — Generate {NUM_TRANSACTIONS:,} transaksi")
print("Memulai proses generate data DW. Harap tunggu...\n")
start_time = time.time()

# 1. DimDate
base_date = datetime(2025, 1, 1)
dim_date_data = []
for i in range(365):
    d = base_date + timedelta(days=i)
    dim_date_data.append({
        'date_key':       i + 1,
        'full_date':      d.strftime('%Y-%m-%d'),
        'day_number':     d.day,
        'day_name':       HARI[d.weekday()],
        'month_number':   d.month,
        'month_name':     BULAN[d.month - 1],
        'quarter_number': (d.month - 1) // 3 + 1,
        'year_number':    d.year,
        'is_weekend':     1 if d.weekday() >= 5 else 0,
    })
pd.DataFrame(dim_date_data).to_csv('../dataset/DimDate.csv', index=False)
print("1/10 - DimDate selesai (365 baris)")

# 2. DimCustomer
dim_customer_data = []
for i in range(1, NUM_CUSTOMERS + 1):
    city_data = random.choice(BRANCH_CITIES)
    dim_customer_data.append({
        'customer_key':     i,
        'customer_id':      f'CUST-{i:05d}',
        'customer_name':    fake.name(),
        'customer_type':    random.choices(CUSTOMER_TYPES, weights=[0.7, 0.2, 0.1])[0],
        'gender':           random.choice(GENDERS),
        'phone':            f"0812{random.randint(10000000, 99999999)}" if random.random() > 0.05 else None,
        'email':            fake.email() if random.random() > 0.08 else None,
        'city':             city_data[0],
        'province':         city_data[1],
        'registration_date': fake.date_between(start_date='-2y', end_date='-1d').strftime('%Y-%m-%d'),
        'is_active':        0 if random.random() < 0.05 else 1,
    })
pd.DataFrame(dim_customer_data).to_csv('../dataset/DimCustomer.csv', index=False)
print(f"2/10 - DimCustomer selesai ({NUM_CUSTOMERS:,} baris)")

# 3. DimBranch
dim_branch_data = []
for i, (city, province, region) in enumerate(BRANCH_CITIES):
    dim_branch_data.append({
        'branch_key':   i + 1,
        'branch_id':    f'BR-{i+1:03d}',
        'branch_name':  f'Cabang {city}',
        'branch_type':  'Pusat' if i == 0 else 'Cabang',
        'address':      fake.address(),
        'city':         city,
        'province':     province,
        'region':       region,
        'manager_name': fake.name(),
        'opening_date': fake.date_between(start_date='-5y', end_date='-1y').strftime('%Y-%m-%d'),
        'is_active':    1,
    })
df_branch = pd.DataFrame(dim_branch_data)
df_branch.to_csv('../dataset/DimBranch.csv', index=False)
print(f"3/10 - DimBranch selesai ({NUM_BRANCHES} baris)")

# 4. DimCourier
branch_ids = df_branch['branch_id'].tolist()
dim_courier_data = []
for i in range(1, NUM_COURIERS + 1):
    dim_courier_data.append({
        'courier_key':     i,
        'courier_id':      f'KR-{i:05d}',
        'courier_name':    fake.name(),
        'gender':          random.choice(GENDERS),
        'phone':           f"0857{random.randint(10000000, 99999999)}",
        'branch_id':       random.choice(branch_ids),
        'vehicle_type':    random.choices(['Motor', 'Mobil Van', 'Mobil Box', 'Sepeda'], weights=[0.55, 0.25, 0.10, 0.10])[0],
        'hire_date':       fake.date_between(start_date='-3y', end_date='-1m').strftime('%Y-%m-%d'),
        'employee_status': random.choices(['Tetap', 'Kontrak', 'Freelance'], weights=[0.5, 0.35, 0.15])[0],
        'is_active':       1,
    })
pd.DataFrame(dim_courier_data).to_csv('../dataset/DimCourier.csv', index=False)
print(f"4/10 - DimCourier selesai ({NUM_COURIERS} baris)")

# 5. DimService
services = [
    (1, 'REG', 'Regular',  'Standard', '3-5 hari',       30.0, 1, 1),
    (2, 'EXP', 'Express',  'Premium',  '1-2 hari',       20.0, 0, 1),
    (3, 'ONS', 'Same Day', 'Premium',  'Hari yang sama', 10.0, 0, 1),
    (4, 'ECO', 'Ekonomi',  'Standard', '5-7 hari',       50.0, 1, 1),
    (5, 'CGO', 'Cargo',    'Logistik', '5-10 hari',     100.0, 0, 1),
    (6, 'INS', 'Instant',  'Premium',  '2-4 jam',         5.0, 0, 1),
]
pd.DataFrame(services, columns=[
    'service_key', 'service_code', 'service_name', 'service_category',
    'delivery_estimation', 'max_weight', 'is_cod_available', 'is_active'
]).to_csv('../dataset/DimService.csv', index=False)
print("5/10 - DimService selesai (6 baris)")

# 6. DimPackage
dim_package_data = []
for i in range(1, NUM_TRANSACTIONS + 1):
    w = round(random.uniform(0.5, 25.0), 2)
    weight_cat = 'Ringan' if w <= 1 else 'Sedang' if w <= 5 else 'Berat' if w <= 15 else 'Sangat Berat'
    l, w_cm, h = random.randint(10, 100), random.randint(10, 100), random.randint(10, 100)
    volume = l * w_cm * h
    dim_package_data.append({
        'package_key':      i,
        'package_id':       f'PKG-{i:07d}',
        'package_type':     random.choice(['Box', 'Plastik', 'Dokumen']),
        'package_category': 'Kecil' if volume < 5000 else 'Sedang' if volume < 50000 else 'Besar',
        'weight':           w,
        'weight_category':  weight_cat,
        'length_cm':        l,
        'width_cm':         w_cm,
        'height_cm':        h,
        'volume_cm3':       volume,
        'is_fragile':       random.choice([0, 1]),
        'is_insured':       random.choice([0, 1]),
        'item_description': random.choice(ITEM_DESCRIPTIONS),
    })
pd.DataFrame(dim_package_data).to_csv('../dataset/DimPackage.csv', index=False)
print(f"6/10 - DimPackage selesai ({NUM_TRANSACTIONS:,} baris)")

# 7. DimPayment
dim_payment_data = []
for i in range(1, NUM_TRANSACTIONS + 1):
    method = random.choices(PAYMENT_METHODS, weights=[0.5, 0.4, 0.1])[0]
    if method == 'Transfer Bank':
        channel, bank = 'Mobile Banking', random.choice(BANKS)
    elif method == 'E-Wallet':
        channel, bank = random.choice(EWALLET_CHANNELS), None
    else:
        channel, bank = 'COD', None
    dim_payment_data.append({
        'payment_key':     i,
        'payment_id':      f'PAY-{i:07d}',
        'payment_method':  method,
        'payment_channel': channel,
        'bank_name':       bank,
        'payment_date':    (base_date + timedelta(days=random.randint(0, 364))).strftime('%Y-%m-%d'),
        'payment_status':  random.choices(['Lunas', 'Pending'], weights=[0.95, 0.05])[0],
        'is_cod':          1 if method == 'COD' else 0,
        'refund_status':   'Tidak Ada',
    })
pd.DataFrame(dim_payment_data).to_csv('../dataset/DimPayment.csv', index=False)
print(f"7/10 - DimPayment selesai ({NUM_TRANSACTIONS:,} baris)")

# 8. DimShipmentStatus
statuses = [
    (1, 'PICKUP',      'Picked Up',         'Proses',  'Paket dijemput dari pengirim'),
    (2, 'INTRANSIT',   'In Transit',         'Proses',  'Dalam perjalanan'),
    (3, 'ONSORTIR',    'On Sorting',         'Proses',  'Sedang disortir di gudang'),
    (4, 'OUTDELIVERY', 'Out for Delivery',   'Proses',  'Sedang diantar ke penerima'),
    (5, 'DELIVERED',   'Delivered',          'Selesai', 'Berhasil diterima penerima'),
    (6, 'FAILED',      'Failed Delivery',    'Gagal',   'Pengiriman gagal'),
    (7, 'RETURNED',    'Returned to Sender', 'Gagal',   'Dikembalikan ke pengirim'),
    (8, 'CANCELLED',   'Cancelled',          'Batal',   'Pengiriman dibatalkan'),
]
pd.DataFrame(statuses, columns=[
    'status_key', 'status_code', 'status_name', 'status_category', 'status_description'
]).to_csv('../dataset/DimShipmentStatus.csv', index=False)
print("8/10 - DimShipmentStatus selesai (8 baris)")

# 9. DimRoute
city_region_map  = {city: region for city, _, region in BRANCH_CITIES}
branch_cities_list = [city for city, _, _ in BRANCH_CITIES]
dim_route_data = []
for i in range(1, NUM_ROUTES + 1):
    origin      = random.choice(branch_cities_list)
    destination = random.choice(branch_cities_list)
    o_region    = city_region_map[origin]
    d_region    = city_region_map[destination]
    if o_region == d_region:
        route_type = 'Intra-Region'
    elif o_region in ['Jabodetabek', 'Jawa'] and d_region in ['Jabodetabek', 'Jawa']:
        route_type = 'Inter-Region (Jawa)'
    else:
        route_type = 'Inter-Region (Luar Jawa)'
    dim_route_data.append({
        'route_key':          i,
        'route_id':           f'RT-{i:03d}',
        'origin_city':        origin,
        'destination_city':   destination,
        'origin_region':      o_region,
        'destination_region': d_region,
        'distance_km':        random.randint(10, 1500),
        'route_type':         route_type,
        'is_active':          1,
    })
pd.DataFrame(dim_route_data).to_csv('../dataset/DimRoute.csv', index=False)
print(f"9/10 - DimRoute selesai ({NUM_ROUTES} baris)")

# 10. FactDeliveryPerformance
IN_PROGRESS_KEYS = [1, 2, 3, 4]
OUTER_CHOICES    = ['delivered', 'in_progress', 'failed', 'cancelled', 'returned']
OUTER_WEIGHTS    = [0.709, 0.177, 0.046, 0.043, 0.026]

fact_data = []
print(f"10/10 - Generate FactDeliveryPerformance ({NUM_TRANSACTIONS:,} baris)...")

for i in range(1, NUM_TRANSACTIONS + 1):
    outer = random.choices(OUTER_CHOICES, weights=OUTER_WEIGHTS)[0]
    if outer == 'delivered':        status_key = 5
    elif outer == 'in_progress':    status_key = random.choice(IN_PROGRESS_KEYS)
    elif outer == 'failed':         status_key = 6
    elif outer == 'cancelled':      status_key = 8
    else:                           status_key = 7

    t_date_key     = random.randint(1, 350)
    p_date_key     = min(t_date_key + random.randint(0, 1), 365)
    estimated_days = random.randint(1, 7)

    if status_key == 5:
        actual_days = max(1, estimated_days + random.randint(-1, 3))
        d_date_key  = p_date_key + actual_days
        if d_date_key > 365:
            d_date_key  = 365
            actual_days = d_date_key - p_date_key
        delay_days = max(0, actual_days - estimated_days)
    else:
        actual_days = None
        d_date_key  = None
        delay_days  = None

    shipping_fee    = random.randint(1, 15) * 10_000
    insurance_fee   = random.choice([0, 5_000, 10_000])
    discount_amount = random.choice([0, 5_000, 10_000]) if random.random() > 0.8 else 0

    fact_data.append({
        'shipment_key':         i,
        'shipment_id':          f'SHP-{i:07d}',
        'awb_number':           f'AWB{20250000000 + i}',
        'transaction_date_key': t_date_key,
        'pickup_date_key':      p_date_key,
        'delivery_date_key':    d_date_key,
        'customer_key':         random.randint(1, NUM_CUSTOMERS),
        'branch_key':           random.randint(1, NUM_BRANCHES),
        'courier_key':          random.randint(1, NUM_COURIERS),
        'service_key':          random.randint(1, 6),
        'package_key':          i,
        'status_key':           status_key,
        'route_key':            random.randint(1, NUM_ROUTES),
        'payment_key':          i,
        'total_shipment':       1,
        'estimated_days':       estimated_days,
        'actual_days':          actual_days,
        'delay_days':           delay_days,
        'package_weight':       dim_package_data[i - 1]['weight'],
        'shipping_fee':         shipping_fee,
        'insurance_fee':        insurance_fee,
        'discount_amount':      discount_amount,
        'total_amount':         shipping_fee + insurance_fee - discount_amount,
        'is_delivered':         1 if status_key == 5 else 0,
        'is_late':              1 if (delay_days and delay_days > 0) else 0,
        'is_failed':            1 if status_key == 6 else 0,
        'is_returned':          1 if status_key == 7 else 0,
        'is_cancelled':         1 if status_key == 8 else 0,
    })

    if i % 10_000 == 0:
        print(f"  → {i:,}/{NUM_TRANSACTIONS:,} baris ({i * 100 // NUM_TRANSACTIONS}%)")

df_fact = pd.DataFrame(fact_data)

for col in ['actual_days', 'delay_days', 'delivery_date_key']:
    df_fact[col] = df_fact[col].astype('Int64')

df_fact.to_csv('../dataset/FactDeliveryPerformance.csv', index=False)
print(f"10/10 - FactDeliveryPerformance selesai ({NUM_TRANSACTIONS:,} baris)")

elapsed = round(time.time() - start_time, 2)
print(f"\nSelesai! Semua file CSV tersimpan di folder 'dataset/' ({elapsed} detik)")
print("\nRingkasan file yang di-generate:")
for f in sorted(os.listdir('dataset')):
    path = f'dataset/{f}'
    df   = pd.read_csv(path)
    print(f"  {f:<45} {len(df):>8,} baris  |  {df.shape[1]} kolom")