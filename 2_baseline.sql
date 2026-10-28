-- File 2: query baseline, sebelum ada indeks tambahan (hanya PRIMARY KEY dan UNIQUE).
-- Setiap query dijalankan 3 kali; yang dibandingkan adalah rata-rata Execution Time.

-- Query 1: Riwayat servis satu motor
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

-- Query 2: Jumlah servis per bulan satu mekanik
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

-- Query 3: Penjualan item mahal
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
