-- File 3: pembuatan indeks, lalu query yang sama dijalankan ulang
-- Setiap query dijalankan 3 kali; waktu yang dipakai adalah rata-ratanya.

\echo '=== Indeks 1 (B-Tree tunggal) untuk query 1'
CREATE INDEX idx_servis_motor ON servis (id_motor);

\echo '=== Indeks 2 (Composite) untuk query 2: kolom = di depan, kolom rentang di belakang'
CREATE INDEX idx_servis_mekanik_tgl ON servis (id_mekanik, tgl_servis);

\echo '=== Indeks 3 (Partial) untuk query 3: hanya baris dengan harga Rp250.000 ke atas'
CREATE INDEX idx_detail_mahal ON detail_servis (harga_saat_servis)
    INCLUDE (id_item, qty)
    WHERE harga_saat_servis >= 250000;

VACUUM ANALYZE servis;
VACUUM ANALYZE detail_servis;

\echo '=== Ukuran indeks'
SELECT indexrelname AS indeks,
       relname AS tabel,
       pg_size_pretty(pg_relation_size(indexrelid)) AS ukuran
FROM pg_stat_user_indexes
WHERE indexrelname IN ('idx_servis_motor', 'idx_servis_mekanik_tgl', 'idx_detail_mahal')
ORDER BY indexrelname;

\echo '=== Query 1: riwayat servis satu motor berdasarkan plat nomor (percobaan 1)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.id_servis, s.tgl_servis, m.nama AS mekanik
FROM servis s
JOIN motor mt  ON mt.id_motor   = s.id_motor
JOIN mekanik m ON m.id_mekanik = s.id_mekanik
WHERE mt.plat_nomor = 'L 1005 AF'
ORDER BY s.tgl_servis;

\echo '=== Query 1: riwayat servis satu motor berdasarkan plat nomor (percobaan 2)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.id_servis, s.tgl_servis, m.nama AS mekanik
FROM servis s
JOIN motor mt  ON mt.id_motor   = s.id_motor
JOIN mekanik m ON m.id_mekanik = s.id_mekanik
WHERE mt.plat_nomor = 'L 1005 AF'
ORDER BY s.tgl_servis;

\echo '=== Query 1: riwayat servis satu motor berdasarkan plat nomor (percobaan 3)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.id_servis, s.tgl_servis, m.nama AS mekanik
FROM servis s
JOIN motor mt  ON mt.id_motor   = s.id_motor
JOIN mekanik m ON m.id_mekanik = s.id_mekanik
WHERE mt.plat_nomor = 'L 1005 AF'
ORDER BY s.tgl_servis;

\echo '=== Query 2: jumlah servis per bulan satu mekanik sejak 1 Januari 2025 (percobaan 1)'
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

\echo '=== Query 2: jumlah servis per bulan satu mekanik sejak 1 Januari 2025 (percobaan 2)'
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

\echo '=== Query 2: jumlah servis per bulan satu mekanik sejak 1 Januari 2025 (percobaan 3)'
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

\echo '=== Query 3: penjualan item mahal (harga Rp250.000 ke atas) per item (percobaan 1)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT i.nama_item,
       COUNT(*) AS jumlah_transaksi,
       SUM(d.qty * d.harga_saat_servis) AS pendapatan
FROM detail_servis d
JOIN item i ON i.id_item = d.id_item
WHERE d.harga_saat_servis >= 250000
GROUP BY i.nama_item
ORDER BY pendapatan DESC;

\echo '=== Query 3: penjualan item mahal (harga Rp250.000 ke atas) per item (percobaan 2)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT i.nama_item,
       COUNT(*) AS jumlah_transaksi,
       SUM(d.qty * d.harga_saat_servis) AS pendapatan
FROM detail_servis d
JOIN item i ON i.id_item = d.id_item
WHERE d.harga_saat_servis >= 250000
GROUP BY i.nama_item
ORDER BY pendapatan DESC;

\echo '=== Query 3: penjualan item mahal (harga Rp250.000 ke atas) per item (percobaan 3)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT i.nama_item,
       COUNT(*) AS jumlah_transaksi,
       SUM(d.qty * d.harga_saat_servis) AS pendapatan
FROM detail_servis d
JOIN item i ON i.id_item = d.id_item
WHERE d.harga_saat_servis >= 250000
GROUP BY i.nama_item
ORDER BY pendapatan DESC;
