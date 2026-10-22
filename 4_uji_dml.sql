-- File 4: uji overhead DML (INSERT, UPDATE, DELETE) tanpa indeks vs dengan indeks
-- Setiap pengujian dibungkus BEGIN ... ROLLBACK, jadi data asli tidak berubah.
-- Setiap skenario dijalankan 3 kali; waktu yang dipakai adalah rata-ratanya.
-- VACUUM sesudah setiap percobaan membersihkan sisa baris yang dibatalkan,
-- supaya ketiga percobaan dimulai dari kondisi tabel yang sama.

\timing on

DROP INDEX IF EXISTS idx_servis_motor;
DROP INDEX IF EXISTS idx_servis_mekanik_tgl;
DROP INDEX IF EXISTS idx_detail_mahal;
VACUUM servis;
VACUUM detail_servis;

\echo '=== TANPA indeks tambahan (percobaan 1)'
BEGIN;
\echo '--- INSERT 50.000 servis'
INSERT INTO servis
SELECT 500000 + i, DATE '2025-01-01' + i % 365, 1 + i % 120000, 1 + i % 60
FROM generate_series(1, 50000) AS i;
\echo '--- INSERT 50.000 detail_servis (harga Rp350.000)'
INSERT INTO detail_servis
SELECT 500000 + i, 7, 1, 350000
FROM generate_series(1, 50000) AS i;
\echo '--- UPDATE 50.000 servis (tanggal dan mekanik diubah)'
UPDATE servis SET tgl_servis = tgl_servis + 1, id_mekanik = 1 + id_mekanik % 60
WHERE id_servis <= 50000;
\echo '--- DELETE 50.000 detail_servis'
DELETE FROM detail_servis WHERE id_servis > 500000;
\echo '--- DELETE 50.000 servis'
DELETE FROM servis WHERE id_servis > 500000;
ROLLBACK;
VACUUM servis;
VACUUM detail_servis;

\echo '=== TANPA indeks tambahan (percobaan 2)'
BEGIN;
\echo '--- INSERT 50.000 servis'
INSERT INTO servis
SELECT 500000 + i, DATE '2025-01-01' + i % 365, 1 + i % 120000, 1 + i % 60
FROM generate_series(1, 50000) AS i;
\echo '--- INSERT 50.000 detail_servis (harga Rp350.000)'
INSERT INTO detail_servis
SELECT 500000 + i, 7, 1, 350000
FROM generate_series(1, 50000) AS i;
\echo '--- UPDATE 50.000 servis (tanggal dan mekanik diubah)'
UPDATE servis SET tgl_servis = tgl_servis + 1, id_mekanik = 1 + id_mekanik % 60
WHERE id_servis <= 50000;
\echo '--- DELETE 50.000 detail_servis'
DELETE FROM detail_servis WHERE id_servis > 500000;
\echo '--- DELETE 50.000 servis'
DELETE FROM servis WHERE id_servis > 500000;
ROLLBACK;
VACUUM servis;
VACUUM detail_servis;

\echo '=== TANPA indeks tambahan (percobaan 3)'
BEGIN;
\echo '--- INSERT 50.000 servis'
INSERT INTO servis
SELECT 500000 + i, DATE '2025-01-01' + i % 365, 1 + i % 120000, 1 + i % 60
FROM generate_series(1, 50000) AS i;
\echo '--- INSERT 50.000 detail_servis (harga Rp350.000)'
INSERT INTO detail_servis
SELECT 500000 + i, 7, 1, 350000
FROM generate_series(1, 50000) AS i;
\echo '--- UPDATE 50.000 servis (tanggal dan mekanik diubah)'
UPDATE servis SET tgl_servis = tgl_servis + 1, id_mekanik = 1 + id_mekanik % 60
WHERE id_servis <= 50000;
\echo '--- DELETE 50.000 detail_servis'
DELETE FROM detail_servis WHERE id_servis > 500000;
\echo '--- DELETE 50.000 servis'
DELETE FROM servis WHERE id_servis > 500000;
ROLLBACK;
VACUUM servis;
VACUUM detail_servis;

CREATE INDEX idx_servis_motor ON servis (id_motor);
CREATE INDEX idx_servis_mekanik_tgl ON servis (id_mekanik, tgl_servis);
CREATE INDEX idx_detail_mahal ON detail_servis (harga_saat_servis)
    INCLUDE (id_item, qty)
    WHERE harga_saat_servis >= 250000;
VACUUM ANALYZE servis;
VACUUM ANALYZE detail_servis;

\echo '=== DENGAN indeks tambahan (percobaan 1)'
BEGIN;
\echo '--- INSERT 50.000 servis'
INSERT INTO servis
SELECT 500000 + i, DATE '2025-01-01' + i % 365, 1 + i % 120000, 1 + i % 60
FROM generate_series(1, 50000) AS i;
\echo '--- INSERT 50.000 detail_servis (harga Rp350.000)'
INSERT INTO detail_servis
SELECT 500000 + i, 7, 1, 350000
FROM generate_series(1, 50000) AS i;
\echo '--- UPDATE 50.000 servis (tanggal dan mekanik diubah)'
UPDATE servis SET tgl_servis = tgl_servis + 1, id_mekanik = 1 + id_mekanik % 60
WHERE id_servis <= 50000;
\echo '--- DELETE 50.000 detail_servis'
DELETE FROM detail_servis WHERE id_servis > 500000;
\echo '--- DELETE 50.000 servis'
DELETE FROM servis WHERE id_servis > 500000;
ROLLBACK;
VACUUM servis;
VACUUM detail_servis;

\echo '=== DENGAN indeks tambahan (percobaan 2)'
BEGIN;
\echo '--- INSERT 50.000 servis'
INSERT INTO servis
SELECT 500000 + i, DATE '2025-01-01' + i % 365, 1 + i % 120000, 1 + i % 60
FROM generate_series(1, 50000) AS i;
\echo '--- INSERT 50.000 detail_servis (harga Rp350.000)'
INSERT INTO detail_servis
SELECT 500000 + i, 7, 1, 350000
FROM generate_series(1, 50000) AS i;
\echo '--- UPDATE 50.000 servis (tanggal dan mekanik diubah)'
UPDATE servis SET tgl_servis = tgl_servis + 1, id_mekanik = 1 + id_mekanik % 60
WHERE id_servis <= 50000;
\echo '--- DELETE 50.000 detail_servis'
DELETE FROM detail_servis WHERE id_servis > 500000;
\echo '--- DELETE 50.000 servis'
DELETE FROM servis WHERE id_servis > 500000;
ROLLBACK;
VACUUM servis;
VACUUM detail_servis;

\echo '=== DENGAN indeks tambahan (percobaan 3)'
BEGIN;
\echo '--- INSERT 50.000 servis'
INSERT INTO servis
SELECT 500000 + i, DATE '2025-01-01' + i % 365, 1 + i % 120000, 1 + i % 60
FROM generate_series(1, 50000) AS i;
\echo '--- INSERT 50.000 detail_servis (harga Rp350.000)'
INSERT INTO detail_servis
SELECT 500000 + i, 7, 1, 350000
FROM generate_series(1, 50000) AS i;
\echo '--- UPDATE 50.000 servis (tanggal dan mekanik diubah)'
UPDATE servis SET tgl_servis = tgl_servis + 1, id_mekanik = 1 + id_mekanik % 60
WHERE id_servis <= 50000;
\echo '--- DELETE 50.000 detail_servis'
DELETE FROM detail_servis WHERE id_servis > 500000;
\echo '--- DELETE 50.000 servis'
DELETE FROM servis WHERE id_servis > 500000;
ROLLBACK;
VACUUM servis;
VACUUM detail_servis;
