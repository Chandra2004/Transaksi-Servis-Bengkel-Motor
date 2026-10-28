# Tugas 1: Transaksi Servis Bengkel Motor

Evaluasi dan optimasi performa query dengan execution plan dan indeks pada studi kasus jaringan bengkel motor dengan 10 cabang.

- RDBMS: PostgreSQL 17.11
- Database: `bengkel_motor`, 8 tabel berelasi (cabang, mekanik, pelanggan, motor, kategori_item, item, servis, detail_servis)
- Volume data dummy: 500.000 servis dan 1.492.530 detail servis, dibuat dengan `generate_series()`

## File

| File | Isi |
|---|---|
| `1_ddl_generator.sql` | DDL 8 tabel (hanya PRIMARY KEY, UNIQUE, FOREIGN KEY) dan generator data dummy |
| `2_baseline.sql` | 3 query target dengan `EXPLAIN (ANALYZE, BUFFERS)` sebelum ada indeks tambahan, masing-masing 3 kali |
| `log_explain_awal.txt` | Output EXPLAIN awal |
| `3_indeks.sql` | Pembuatan indeks untuk setiap query, query yang sama dijalankan ulang 3 kali, lalu ukuran indeks |
| `log_explain_akhir.txt` | Output EXPLAIN akhir dan ukuran indeks |
| `4_uji_dml.sql` | Uji INSERT, UPDATE, DELETE tanpa indeks vs dengan indeks, masing-masing 3 kali |
| `log_uji_dml.txt` | Output uji DML |

## Cara menjalankan

Syarat: PostgreSQL sudah terpasang dan perintah `psql` serta `createdb` bisa dipakai. Jalankan berurutan dari folder ini:

```sh
createdb bengkel_motor
psql -d bengkel_motor -f 1_ddl_generator.sql
psql -d bengkel_motor -f 2_baseline.sql
psql -d bengkel_motor -f 3_indeks.sql
psql -d bengkel_motor -f 4_uji_dml.sql
```

Karena memakai `setseed`, data yang dihasilkan selalu sama. Waktu eksekusi bisa sedikit berbeda di setiap komputer.

## Query dan strategi indeks

Ketiga query memakai WHERE, JOIN, dan GROUP BY atau ORDER BY.

| No | Query | Strategi indeks |
|---|---|---|
| 1 | Riwayat servis satu motor berdasarkan plat nomor | B-Tree tunggal `servis (id_motor)` |
| 2 | Jumlah servis per bulan satu mekanik sejak 1 Januari 2025 | Composite `servis (id_mekanik, tgl_servis)` |
| 3 | Penjualan item seharga Rp250.000 ke atas per item | Partial `detail_servis (harga_saat_servis) INCLUDE (id_item, qty) WHERE harga_saat_servis >= 250000` |

## Hasil

### Waktu eksekusi (3 percobaan)

| Query | Tanpa indeks | Rata-rata | Dengan indeks | Rata-rata | Lebih cepat |
|---|---|---|---|---|---|
| 1 | 26,754 / 32,136 / 29,343 ms | 29,411 ms | 0,156 / 0,300 / 0,397 ms | 0,284 ms | 99,0% |
| 2 | 19,464 / 22,768 / 23,984 ms | 22,072 ms | 7,352 / 8,465 / 7,951 ms | 7,923 ms | 64,1% |
| 3 | 48,639 / 51,073 / 49,046 ms | 49,586 ms | 28,022 / 26,869 / 19,685 ms | 24,859 ms | 49,9% |

### Tabel perbandingan

| Query | Strategi indeks | Scan tanpa indeks | Scan dengan indeks | Cost tanpa / dengan | Rows examined tanpa / dengan | Ukuran indeks |
|---|---|---|---|---|---|---|
| 1 | B-Tree tunggal `servis (id_motor)` | Parallel Seq Scan | Bitmap Index Scan | 7.425 / 33 | 500.000 / 8 | 6.232 kB |
| 2 | Composite `servis (id_mekanik, tgl_servis)` | Parallel Seq Scan | Index Only Scan | 8.504 / 213 | 500.000 / 2.821 | 4.960 kB |
| 3 | Partial `detail_servis (harga_saat_servis) INCLUDE (id_item, qty) WHERE harga_saat_servis >= 250000` | Parallel Seq Scan | Parallel Index Only Scan | 17.830 / 6.332 | 1.492.530 / 177.894 | 5.504 kB |

### Pengaruh indeks terhadap JOIN

| Query | Tanpa indeks | Dengan indeks | Keterangan |
|---|---|---|---|
| 1 | Hash Join | Nested Loop | Berubah, karena baris yang digabung tinggal 8 |
| 2 | Nested Loop | Nested Loop | Tetap, tabel mekanik hanya 1 baris |
| 3 | Hash Join | Hash Join | Tetap, tabel item hanya 142 baris |

### Overhead DML (50.000 baris, 3 percobaan)

| Operasi | Tanpa indeks | Rata-rata | Dengan indeks | Rata-rata | Selisih | Perubahan |
|---|---|---|---|---|---|---|
| INSERT 50.000 servis | 297,3 / 281,9 / 295,1 ms | 291,4 ms | 430,9 / 358,2 / 372,3 ms | 387,1 ms | +95,7 ms | +32,8% |
| INSERT 50.000 detail_servis | 266,4 / 263,9 / 275,4 ms | 268,6 ms | 307,4 / 304,6 / 301,4 ms | 304,5 ms | +35,9 ms | +13,4% |
| UPDATE 50.000 servis | 215,9 / 230,2 / 224,4 ms | 223,5 ms | 402,9 / 382,3 / 365,4 ms | 383,5 ms | +160,0 ms | +71,6% |
| DELETE 50.000 detail_servis | 12,7 / 15,9 / 14,2 ms | 14,3 ms | 24,6 / 21,4 / 25,8 ms | 23,9 ms | +9,7 ms | +67,7% |
| DELETE 50.000 servis | 200,4 / 204,6 / 191,7 ms | 198,9 ms | 206,1 / 198,2 / 201,1 ms | 201,8 ms | +2,9 ms | +1,5% |

## Analisis

**Query 1 (B-Tree tunggal).** Bottleneck: seluruh tabel `servis` dibaca hanya untuk mencari 8 nota. Berhasil, 99,0% lebih cepat, karena indeks langsung menunjuk ke 8 nota tersebut.

**Query 2 (Composite).** Bottleneck: seluruh tabel `servis` dibaca, padahal yang dibutuhkan hanya 2.821 nota milik mekanik 7 sejak 2025. Berhasil, 64,1% lebih cepat. Kolom `id_mekanik` ditaruh di depan karena dicari dengan tanda sama dengan (leftmost prefix), dan semua kolom yang dibutuhkan sudah ada di indeks sehingga tabel tidak perlu dibaca lagi.

**Query 3 (Partial).** Bottleneck: 1.492.530 baris dibaca, padahal yang dibutuhkan hanya 177.894 baris berharga Rp250.000 ke atas. Berhasil, 49,9% lebih cepat, tetapi paling kecil, karena 177.894 baris hasilnya tetap harus dijumlahkan. Indeksnya hanya menyimpan baris berharga Rp250.000 ke atas sehingga ukurannya kecil.

**Overhead DML.** Indeks memperlambat proses menulis karena setiap perubahan data juga harus dicatat di indeks. UPDATE paling terdampak (+160,0 ms) karena kolom yang diubah ada di indeks composite.

## Kesimpulan

Sebelum ada indeks, ketiga query lambat karena PostgreSQL membaca seluruh tabel (Seq Scan), padahal baris yang dibutuhkan hanya sedikit. Setelah indeks dibuat, pembacaan seluruh tabel berubah menjadi pembacaan lewat indeks, sehingga Query 1 dengan B-Tree tunggal menjadi 99,0% lebih cepat, Query 2 dengan indeks composite 64,1% lebih cepat, dan Query 3 dengan partial index 49,9% lebih cepat. Manfaat indeks paling besar ketika baris yang dicari sangat sedikit dibanding isi tabel, dan pada Query 1 indeks bahkan mengubah cara penggabungan tabel dari Hash Join menjadi Nested Loop.

Namun indeks juga punya harga. Setiap perubahan data harus ikut dicatat di indeks, sehingga INSERT menjadi 13,4% sampai 32,8% lebih lambat dan UPDATE 71,6% lebih lambat. Karena itu indeks sebaiknya dibuat hanya pada kolom yang sering dipakai untuk mencari atau menggabungkan data di query yang sering dijalankan.
