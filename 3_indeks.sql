-- File 3: pembuatan indeks, lalu query yang sama dijalankan ulang 3 kali.
-- VACUUM ANALYZE memperbarui statistik tabel setelah indeks dibuat.

-- Query 1: Riwayat servis satu motor (B-Tree tunggal)
CREATE INDEX idx_servis_motor ON servis (id_motor);
VACUUM ANALYZE servis;

EXPLAIN (ANALYZE, BUFFERS)
SELECT s.id_servis, s.tgl_servis, m.nama AS mekanik
FROM servis s
JOIN motor mt  ON mt.id_motor   = s.id_motor
JOIN mekanik m ON m.id_mekanik = s.id_mekanik
WHERE mt.plat_nomor = 'L 1005 AF'
ORDER BY s.tgl_servis;

EXPLAIN (ANALYZE, BUFFERS)
SELECT s.id_servis, s.tgl_servis, m.nama AS mekanik
FROM servis s
JOIN motor mt  ON mt.id_motor   = s.id_motor
JOIN mekanik m ON m.id_mekanik = s.id_mekanik
WHERE mt.plat_nomor = 'L 1005 AF'
ORDER BY s.tgl_servis;

EXPLAIN (ANALYZE, BUFFERS)
SELECT s.id_servis, s.tgl_servis, m.nama AS mekanik
FROM servis s
JOIN motor mt  ON mt.id_motor   = s.id_motor
JOIN mekanik m ON m.id_mekanik = s.id_mekanik
WHERE mt.plat_nomor = 'L 1005 AF'
ORDER BY s.tgl_servis;

-- Query 2: Jumlah servis per bulan satu mekanik (Composite)
CREATE INDEX idx_servis_mekanik_tgl ON servis (id_mekanik, tgl_servis);
VACUUM ANALYZE servis;

EXPLAIN (ANALYZE, BUFFERS)
SELECT m.nama AS mekanik,
       TO_CHAR(s.tgl_servis, 'YYYY-MM') AS bulan,
       COUNT(*) AS jumlah_servis
FROM servis s
JOIN mekanik m ON m.id_mekanik = s.id_mekanik
WHERE s.id_mekanik = 7
  AND s.tgl_servis >= '2025-01-01'
GROUP BY m.nama, bulan
ORDER BY bulan;

EXPLAIN (ANALYZE, BUFFERS)
SELECT m.nama AS mekanik,
       TO_CHAR(s.tgl_servis, 'YYYY-MM') AS bulan,
       COUNT(*) AS jumlah_servis
FROM servis s
JOIN mekanik m ON m.id_mekanik = s.id_mekanik
WHERE s.id_mekanik = 7
  AND s.tgl_servis >= '2025-01-01'
GROUP BY m.nama, bulan
ORDER BY bulan;

EXPLAIN (ANALYZE, BUFFERS)
SELECT m.nama AS mekanik,
       TO_CHAR(s.tgl_servis, 'YYYY-MM') AS bulan,
       COUNT(*) AS jumlah_servis
FROM servis s
JOIN mekanik m ON m.id_mekanik = s.id_mekanik
WHERE s.id_mekanik = 7
  AND s.tgl_servis >= '2025-01-01'
GROUP BY m.nama, bulan
ORDER BY bulan;

-- Query 3: Penjualan item mahal (Partial)
CREATE INDEX idx_detail_mahal ON detail_servis (harga_saat_servis)
    INCLUDE (id_item, qty)
    WHERE harga_saat_servis >= 250000;
VACUUM ANALYZE detail_servis;

EXPLAIN (ANALYZE, BUFFERS)
SELECT i.nama_item,
       COUNT(*) AS jumlah_transaksi,
       SUM(d.qty * d.harga_saat_servis) AS pendapatan
FROM detail_servis d
JOIN item i ON i.id_item = d.id_item
WHERE d.harga_saat_servis >= 250000
GROUP BY i.nama_item
ORDER BY pendapatan DESC;

EXPLAIN (ANALYZE, BUFFERS)
SELECT i.nama_item,
       COUNT(*) AS jumlah_transaksi,
       SUM(d.qty * d.harga_saat_servis) AS pendapatan
FROM detail_servis d
JOIN item i ON i.id_item = d.id_item
WHERE d.harga_saat_servis >= 250000
GROUP BY i.nama_item
ORDER BY pendapatan DESC;

EXPLAIN (ANALYZE, BUFFERS)
SELECT i.nama_item,
       COUNT(*) AS jumlah_transaksi,
       SUM(d.qty * d.harga_saat_servis) AS pendapatan
FROM detail_servis d
JOIN item i ON i.id_item = d.id_item
WHERE d.harga_saat_servis >= 250000
GROUP BY i.nama_item
ORDER BY pendapatan DESC;

-- Ukuran ketiga indeks
SELECT indexrelname AS indeks, relname AS tabel,
       pg_size_pretty(pg_relation_size(indexrelid)) AS ukuran
FROM pg_stat_user_indexes
WHERE indexrelname IN ('idx_servis_motor', 'idx_servis_mekanik_tgl', 'idx_detail_mahal')
ORDER BY indexrelname;
