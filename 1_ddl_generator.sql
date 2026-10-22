-- File 1: DDL tabel dan generator data dummy
-- Studi kasus: transaksi servis bengkel motor (10 cabang)
-- Hanya PRIMARY KEY, UNIQUE, dan FOREIGN KEY. Belum ada indeks tambahan.

CREATE TABLE cabang (
    id_cabang   INT PRIMARY KEY,
    nama_cabang VARCHAR(50) NOT NULL,
    kota        VARCHAR(30) NOT NULL
);

CREATE TABLE mekanik (
    id_mekanik INT PRIMARY KEY,
    nama       VARCHAR(50) NOT NULL,
    id_cabang  INT NOT NULL REFERENCES cabang (id_cabang)
);

CREATE TABLE pelanggan (
    id_pelanggan INT PRIMARY KEY,
    nama         VARCHAR(50) NOT NULL,
    no_hp        VARCHAR(15) NOT NULL
);

CREATE TABLE motor (
    id_motor     INT PRIMARY KEY,
    plat_nomor   VARCHAR(12) NOT NULL UNIQUE,
    tipe_motor   VARCHAR(30) NOT NULL,
    tahun        INT NOT NULL,
    id_pelanggan INT NOT NULL REFERENCES pelanggan (id_pelanggan)
);

CREATE TABLE kategori_item (
    id_kategori   INT PRIMARY KEY,
    nama_kategori VARCHAR(20) NOT NULL
);

CREATE TABLE item (
    id_item     INT PRIMARY KEY,
    nama_item   VARCHAR(60) NOT NULL,
    harga       INT NOT NULL,
    id_kategori INT NOT NULL REFERENCES kategori_item (id_kategori)
);

CREATE TABLE servis (
    id_servis  INT PRIMARY KEY,
    tgl_servis DATE NOT NULL,
    id_motor   INT NOT NULL REFERENCES motor (id_motor),
    id_mekanik INT NOT NULL REFERENCES mekanik (id_mekanik)
);

CREATE TABLE detail_servis (
    id_servis         INT NOT NULL REFERENCES servis (id_servis),
    id_item           INT NOT NULL REFERENCES item (id_item),
    qty               INT NOT NULL,
    harga_saat_servis INT NOT NULL,  -- harga item saat transaksi, tidak ikut berubah jika harga item naik
    PRIMARY KEY (id_servis, id_item)
);

-- Generator data dummy (SQL murni: generate_series + random)
-- Hasil: 500.000 servis dan sekitar 1,5 juta detail_servis.
-- setseed membuat data acak yang sama setiap kali dijalankan ulang.

SELECT setseed(0.42);

-- 10 cabang di Jawa Timur
INSERT INTO cabang
SELECT i, 'Bengkel ' || kota, kota
FROM unnest(ARRAY['Surabaya','Sidoarjo','Gresik','Malang','Mojokerto',
                  'Pasuruan','Kediri','Madiun','Jember','Banyuwangi'])
     WITH ORDINALITY AS t(kota, i);

-- 60 mekanik, 6 per cabang
INSERT INTO mekanik
SELECT i,
       (ARRAY['Agus','Budi','Joko','Eko','Rudi','Dedi','Hadi','Arif','Yanto','Slamet'])[1 + (i - 1) % 10]
       || ' ' ||
       (ARRAY['Santoso','Wijaya','Prasetyo','Saputra','Hidayat','Setiawan'])[1 + (i - 1) / 10],
       1 + (i - 1) % 10
FROM generate_series(1, 60) AS i;

-- 100.000 pelanggan
INSERT INTO pelanggan
SELECT i,
       (ARRAY['Andi','Bayu','Citra','Dewi','Fajar','Gilang','Hana','Indra','Joni','Kartika',
              'Lukman','Maya','Nanda','Putri','Rizki','Sari','Tono','Wulan','Yusuf','Zahra'])[1 + floor(random() * 20)::int]
       || ' ' ||
       (ARRAY['Pratama','Kusuma','Nugroho','Wibowo','Lestari','Utomo','Rahman','Syahputra','Anggraini','Firmansyah'])[1 + floor(random() * 10)::int],
       '08' || lpad(i::text, 10, '0')
FROM generate_series(1, 100000) AS i;

-- 120.000 motor: setiap pelanggan punya 1 motor, 20.000 pelanggan punya motor kedua
INSERT INTO motor
SELECT i,
       'L ' || (1000 + i % 9000) || ' ' || chr(65 + i / 9000) || chr(65 + i % 26),
       (ARRAY['Vario 125','Beat','Scoopy','PCX 160','Supra X 125','CBR150R',
              'NMAX','Aerox 155','Mio M3','Vixion','Satria F150','Nex II'])[1 + floor(random() * 12)::int],
       2012 + floor(random() * 13)::int,
       CASE WHEN i <= 100000 THEN i ELSE 1 + floor(random() * 100000)::int END
FROM generate_series(1, 120000) AS i;

-- 4 kategori item
INSERT INTO kategori_item VALUES
    (1, 'Jasa'), (2, 'Oli'), (3, 'Sparepart'), (4, 'Aksesoris');

-- 142 item. Jasa dimasukkan duluan supaya id_item 1-10 = Jasa.
INSERT INTO item
SELECT row_number() OVER (ORDER BY urut, nama), nama, harga, kategori
FROM (
    -- 10 jasa
    SELECT 1 AS urut, nama, harga, 1 AS kategori
    FROM (VALUES ('Servis Ringan', 50000), ('Servis Besar', 150000), ('Ganti Oli', 10000),
                 ('Tune Up', 75000), ('Servis CVT', 60000), ('Servis Injeksi', 85000),
                 ('Bongkar Mesin', 350000), ('Pasang Ban', 15000), ('Setel Rantai', 20000),
                 ('Cuci Motor', 15000)) AS j(nama, harga)
    UNION ALL
    -- 16 oli: 8 merek x 2 ukuran
    SELECT 2, m || ' ' || u, h + (CASE u WHEN '1 L' THEN 10000 ELSE 0 END), 2
    FROM (VALUES ('Yamalube', 42000), ('AHM MPX1', 45000), ('AHM MPX2', 43000),
                 ('Shell Advance', 55000), ('Castrol Power1', 60000), ('Motul 5100', 95000),
                 ('Federal Oil', 38000), ('Enduro 4T', 40000)) AS o(m, h)
    CROSS JOIN (VALUES ('0.8 L'), ('1 L')) AS s(u)
    UNION ALL
    -- 96 sparepart: 16 jenis x 6 merek
    SELECT 3, p || ' ' || m, h * f / 100, 3
    FROM (VALUES ('Kampas Rem Depan', 45000), ('Kampas Rem Belakang', 40000), ('Busi', 20000),
                 ('Aki', 250000), ('Filter Udara', 55000), ('V-Belt', 120000),
                 ('Roller', 50000), ('Rantai', 110000), ('Gear Set', 230000),
                 ('Ban Depan', 230000), ('Ban Belakang', 270000), ('Lampu Depan', 35000),
                 ('Kabel Gas', 30000), ('Kabel Kopling', 30000), ('Bearing Roda', 40000),
                 ('Seal Shock', 25000)) AS p(p, h)
    CROSS JOIN (VALUES ('Honda Genuine', 120), ('Yamaha Genuine', 120), ('Aspira', 100),
                       ('Federal', 90), ('Daytona', 110), ('KTC', 85)) AS mm(m, f)
    UNION ALL
    -- 20 aksesoris: 10 jenis x 2 varian
    SELECT 4, a || ' ' || v, h * f / 100, 4
    FROM (VALUES ('Spion', 35000), ('Cover Jok', 50000), ('Helm Half Face', 180000),
                 ('Helm Full Face', 350000), ('Sarung Tangan', 40000), ('Jas Hujan', 90000),
                 ('Gantungan Barang', 15000), ('Cover Motor', 75000), ('Footstep', 60000),
                 ('Holder HP', 45000)) AS a(a, h)
    CROSS JOIN (VALUES ('Standar', 100), ('Premium', 160)) AS vv(v, f)
) AS semua;

-- 500.000 servis, tanggal acak 2023-01-01 s.d. 2025-12-31
INSERT INTO servis
SELECT i,
       DATE '2023-01-01' + floor(random() * 1096)::int,
       1 + floor(random() * 120000)::int,
       1 + floor(random() * 60)::int
FROM generate_series(1, 500000) AS i;

-- Detail servis: 1-5 item per servis (rata-rata 3).
-- Item pertama selalu jasa, sisanya oli/sparepart/aksesoris.
-- DISTINCT ON membuang item kembar di servis yang sama (PK id_servis + id_item).
INSERT INTO detail_servis
SELECT DISTINCT ON (d.id_servis, d.id_item)
       d.id_servis, d.id_item, d.qty, i.harga
FROM (
    SELECT s.id_servis,
           CASE WHEN g = 1 THEN 1 + floor(random() * 10)::int
                ELSE 11 + floor(random() * 132)::int END AS id_item,
           CASE WHEN g > 1 AND random() < 0.2 THEN 2 ELSE 1 END AS qty  -- jasa selalu 1
    FROM servis s
    CROSS JOIN LATERAL generate_series(1, 1 + s.id_servis % 5) AS g
) AS d
JOIN item i ON i.id_item = d.id_item;

ANALYZE;
