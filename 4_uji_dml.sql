-- File 4: uji overhead DML (INSERT, UPDATE, DELETE 50.000 baris) tanpa indeks vs dengan indeks.
-- Setiap percobaan dibungkus BEGIN ... ROLLBACK sehingga data asli tidak berubah,
-- lalu VACUUM supaya percobaan berikutnya dimulai dari kondisi tabel yang sama.

\timing on

-- Tanpa indeks tambahan
DROP INDEX IF EXISTS idx_servis_motor;
DROP INDEX IF EXISTS idx_servis_mekanik_tgl;
DROP INDEX IF EXISTS idx_detail_mahal;
VACUUM servis;
VACUUM detail_servis;

BEGIN;
INSERT INTO servis
SELECT 500000 + i, DATE '2025-01-01' + i % 365, 1 + i % 120000, 1 + i % 60
FROM generate_series(1, 50000) AS i;
INSERT INTO detail_servis
SELECT 500000 + i, 7, 1, 350000
FROM generate_series(1, 50000) AS i;
UPDATE servis SET tgl_servis = tgl_servis + 1, id_mekanik = 1 + id_mekanik % 60
WHERE id_servis <= 50000;
DELETE FROM detail_servis WHERE id_servis > 500000;
DELETE FROM servis WHERE id_servis > 500000;
ROLLBACK;
VACUUM servis;
VACUUM detail_servis;

BEGIN;
INSERT INTO servis
SELECT 500000 + i, DATE '2025-01-01' + i % 365, 1 + i % 120000, 1 + i % 60
FROM generate_series(1, 50000) AS i;
INSERT INTO detail_servis
SELECT 500000 + i, 7, 1, 350000
FROM generate_series(1, 50000) AS i;
UPDATE servis SET tgl_servis = tgl_servis + 1, id_mekanik = 1 + id_mekanik % 60
WHERE id_servis <= 50000;
DELETE FROM detail_servis WHERE id_servis > 500000;
DELETE FROM servis WHERE id_servis > 500000;
ROLLBACK;
VACUUM servis;
VACUUM detail_servis;

BEGIN;
INSERT INTO servis
SELECT 500000 + i, DATE '2025-01-01' + i % 365, 1 + i % 120000, 1 + i % 60
FROM generate_series(1, 50000) AS i;
INSERT INTO detail_servis
SELECT 500000 + i, 7, 1, 350000
FROM generate_series(1, 50000) AS i;
UPDATE servis SET tgl_servis = tgl_servis + 1, id_mekanik = 1 + id_mekanik % 60
WHERE id_servis <= 50000;
DELETE FROM detail_servis WHERE id_servis > 500000;
DELETE FROM servis WHERE id_servis > 500000;
ROLLBACK;
VACUUM servis;
VACUUM detail_servis;

-- Dengan ketiga indeks
CREATE INDEX idx_servis_motor ON servis (id_motor);
CREATE INDEX idx_servis_mekanik_tgl ON servis (id_mekanik, tgl_servis);
CREATE INDEX idx_detail_mahal ON detail_servis (harga_saat_servis)
    INCLUDE (id_item, qty)
    WHERE harga_saat_servis >= 250000;
VACUUM ANALYZE servis;
VACUUM ANALYZE detail_servis;

BEGIN;
INSERT INTO servis
SELECT 500000 + i, DATE '2025-01-01' + i % 365, 1 + i % 120000, 1 + i % 60
FROM generate_series(1, 50000) AS i;
INSERT INTO detail_servis
SELECT 500000 + i, 7, 1, 350000
FROM generate_series(1, 50000) AS i;
UPDATE servis SET tgl_servis = tgl_servis + 1, id_mekanik = 1 + id_mekanik % 60
WHERE id_servis <= 50000;
DELETE FROM detail_servis WHERE id_servis > 500000;
DELETE FROM servis WHERE id_servis > 500000;
ROLLBACK;
VACUUM servis;
VACUUM detail_servis;

BEGIN;
INSERT INTO servis
SELECT 500000 + i, DATE '2025-01-01' + i % 365, 1 + i % 120000, 1 + i % 60
FROM generate_series(1, 50000) AS i;
INSERT INTO detail_servis
SELECT 500000 + i, 7, 1, 350000
FROM generate_series(1, 50000) AS i;
UPDATE servis SET tgl_servis = tgl_servis + 1, id_mekanik = 1 + id_mekanik % 60
WHERE id_servis <= 50000;
DELETE FROM detail_servis WHERE id_servis > 500000;
DELETE FROM servis WHERE id_servis > 500000;
ROLLBACK;
VACUUM servis;
VACUUM detail_servis;

BEGIN;
INSERT INTO servis
SELECT 500000 + i, DATE '2025-01-01' + i % 365, 1 + i % 120000, 1 + i % 60
FROM generate_series(1, 50000) AS i;
INSERT INTO detail_servis
SELECT 500000 + i, 7, 1, 350000
FROM generate_series(1, 50000) AS i;
UPDATE servis SET tgl_servis = tgl_servis + 1, id_mekanik = 1 + id_mekanik % 60
WHERE id_servis <= 50000;
DELETE FROM detail_servis WHERE id_servis > 500000;
DELETE FROM servis WHERE id_servis > 500000;
ROLLBACK;
VACUUM servis;
VACUUM detail_servis;
