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
| `log_explain_awal.txt` | Output `2_baseline.sql` |
| `3_indeks.sql` | Pembuatan 3 indeks, ukuran indeks, lalu 3 query yang sama dijalankan ulang masing-masing 3 kali |
| `log_explain_akhir.txt` | Output `3_indeks.sql` |
| `4_uji_dml.sql` | Uji INSERT, UPDATE, DELETE tanpa indeks vs dengan indeks, masing-masing 3 kali |
| `log_uji_dml.txt` | Output `4_uji_dml.sql` |

## Cara menjalankan

Syarat: PostgreSQL sudah terpasang dan perintah `psql` serta `createdb` bisa dipakai. Jalankan berurutan dari folder repositori ini:

```sh
createdb bengkel_motor
psql -d bengkel_motor -f 1_ddl_generator.sql
psql -d bengkel_motor -f 2_baseline.sql
psql -d bengkel_motor -f 3_indeks.sql
psql -d bengkel_motor -f 4_uji_dml.sql
```

`1_ddl_generator.sql` membutuhkan sekitar 15 detik. Karena memakai `setseed`, data yang dihasilkan selalu sama. `4_uji_dml.sql` membungkus setiap pengujian dengan `BEGIN ... ROLLBACK`, jadi data tidak berubah setelah dijalankan. Di antara percobaan dijalankan `VACUUM` supaya sisa baris yang dibatalkan tidak memengaruhi percobaan berikutnya.

## Query dan strategi indeks

Ketiga query memakai WHERE, JOIN, dan GROUP BY atau ORDER BY.

| No | Query | Strategi indeks |
|---|---|---|
| 1 | Riwayat servis satu motor berdasarkan plat nomor | B-Tree tunggal `servis (id_motor)` |
| 2 | Jumlah servis per bulan satu mekanik sejak 1 Januari 2025 | Composite `servis (id_mekanik, tgl_servis)` |
| 3 | Penjualan item seharga Rp250.000 ke atas per item | Partial `detail_servis (harga_saat_servis) INCLUDE (id_item, qty) WHERE harga_saat_servis >= 250000` |

## Hasil

Setiap pengujian dijalankan 3 kali, dan waktu yang dibandingkan adalah rata-ratanya. Angka bisa sedikit berbeda di setiap komputer.

### Waktu query

| Query | Sebelum (3 percobaan) | Rata-rata sebelum | Sesudah (3 percobaan) | Rata-rata sesudah | Lebih cepat |
|---|---|---|---|---|---|
| 1 | 15,01 / 14,43 / 14,41 ms | 14,62 ms | 0,034 / 0,025 / 0,016 ms | 0,025 ms | 99,8% |
| 2 | 10,11 / 8,87 / 8,89 ms | 9,29 ms | 2,42 / 0,81 / 0,80 ms | 1,34 ms | 85,6% |
| 3 | 29,52 / 29,36 / 29,09 ms | 29,32 ms | 12,93 / 12,22 / 11,92 ms | 12,36 ms | 57,9% |

### Execution plan

| Query | Scan sebelum | Scan sesudah | Cost sebelum | Cost sesudah | Buffer sebelum | Buffer sesudah | Ukuran indeks |
|---|---|---|---|---|---|---|---|
| 1 | Parallel Seq Scan `servis` | Bitmap Index Scan `idx_servis_motor` | 7.425 | 33 | 2.785 | 31 | 6.232 kB |
| 2 | Parallel Seq Scan `servis` | Index Only Scan `idx_servis_mekanik_tgl` | 8.531 | 202 | 2.707 | 11 | 4.960 kB |
| 3 | Parallel Seq Scan `detail_servis` | Parallel Index Only Scan `idx_detail_mahal` | 17.838 | 6.338 | 8.121 | 780 | 5.504 kB |

### Overhead DML (50.000 baris)

| Operasi | Tanpa indeks (3 percobaan) | Rata-rata | Dengan indeks (3 percobaan) | Rata-rata | Perubahan |
|---|---|---|---|---|---|
| INSERT servis | 296,4 / 299,7 / 298,1 ms | 298,1 ms | 468,3 / 486,5 / 431,5 ms | 462,1 ms | +55,0% |
| INSERT detail_servis | 298,9 / 293,7 / 293,8 ms | 295,5 ms | 368,0 / 368,0 / 359,4 ms | 365,1 ms | +23,6% |
| UPDATE servis | 297,4 / 258,4 / 259,1 ms | 271,7 ms | 569,9 / 484,9 / 371,6 ms | 475,5 ms | +75,0% |
| DELETE detail_servis | 17,9 / 15,0 / 9,7 ms | 14,2 ms | 50,5 / 38,9 / 8,5 ms | 32,6 ms | +129,6% |
| DELETE servis | 203,2 / 197,6 / 196,0 ms | 198,9 ms | 184,1 / 191,7 / 178,8 ms | 184,9 ms | -7,1% |

## Analisis

**Query 1 (B-Tree tunggal).** Sebelum ada indeks, PostgreSQL membaca seluruh 500.000 baris `servis` (Parallel Seq Scan) hanya untuk menemukan 8 nota milik satu motor. Itulah bottleneck-nya. Indeks `servis (id_motor)` membuat 8 nota itu bisa langsung diambil, sehingga blok yang dibaca turun dari 2.785 menjadi 31 dan waktunya turun 99,8%.

**Query 2 (Composite).** Bottleneck-nya sama: seluruh tabel `servis` dibaca lalu disaring dua syarat. Urutan kolom indeks mengikuti aturan leftmost prefix: `id_mekanik` (dicari dengan `=`) di depan, `tgl_servis` (rentang `>=`) di belakang, sehingga data yang cocok berada berdampingan di indeks. Hasilnya Index Only Scan yang hanya membaca 11 blok. Percobaan pertama sesudah indeks lebih lambat (2,42 ms) karena halaman indeks masih dibaca dari disk; percobaan berikutnya sudah dari cache.

**Query 3 (Partial).** Bottleneck-nya pembacaan penuh 1,49 juta baris `detail_servis`, padahal yang dibutuhkan hanya 177.895 baris (11,9%) dengan harga Rp250.000 ke atas. Partial index hanya menyimpan baris-baris itu, sehingga ukurannya 5,5 MB, jauh lebih kecil dari indeks penuh pada kolom yang sama (45 MB). Peningkatannya paling kecil (57,9%) karena hasilnya tetap 177.895 baris yang harus dijumlahkan; indeks hanya menghemat pembacaan baris yang tidak dibutuhkan.

**Pengaruh indeks pada JOIN.** Di query 1, `servis` dan `motor` awalnya digabung dengan Hash Join setelah seluruh `servis` dibaca. Setelah ada indeks, PostgreSQL memilih Nested Loop: motor dicari lewat indeks plat nomor, lalu servisnya diambil lewat `idx_servis_motor`. Query 2 tetap Nested Loop karena `mekanik` hanya menghasilkan 1 baris. Query 3 tetap Hash Join karena tabel `item` hanya 142 baris dan lebih murah di-hash; yang berubah hanya cara membaca `detail_servis`.

**Overhead DML.** Indeks mempercepat baca tetapi memperlambat tulis:
- INSERT ke `servis` 55% lebih lambat karena setiap baris baru harus dimasukkan ke 2 indeks tambahan. INSERT ke `detail_servis` 23,6% lebih lambat karena semua baris uji berharga Rp350.000, sehingga semuanya ikut masuk ke partial index.
- UPDATE paling terdampak (+75%) karena kolom yang diubah (`tgl_servis` dan `id_mekanik`) ada di indeks composite, sehingga entri lama di indeks harus diganti dengan entri baru.
- DELETE `servis` hampir tidak berubah (-7,1%). Di PostgreSQL, DELETE hanya menandai baris sebagai terhapus; entri indeksnya baru dibersihkan kemudian oleh VACUUM. DELETE `detail_servis` terlihat naik, tetapi selisihnya hanya belasan milidetik dan hasil ketiga percobaannya bervariasi jauh, jadi tidak bisa disimpulkan sebagai beban indeks.
