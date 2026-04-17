# Klipah

## ⚡ Cara Instalasi Instan

Klipah dapat di-*deploy* langsung ke komputer manapun secara otomatis lewat satu baris perintah di PowerShell.

1. Buka **PowerShell** (tekan `Windows`, ketik "PowerShell", buka sebagai Administrator lebih direkomendasikan).
2. Salin (*copy*) seluruh baris perintah di bawah ini dan _paste_ pada PowerShell, lalu tekan **Enter**:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Ibnuard/codename-kppjyt/master/install.ps1'))
```

3. Setup otomatis akan berjalan. Pada langkah pertama, installer akan meminta **Secure Token** (Lisensi Anda). Masukkan Token yang diberikan oleh Admin. 
4. Selesai! Restart terminal PowerShell Anda.

---

## 🎮 Command Operasional

Setelah terinstal, gunakan perintah terminal berikut di CMD atau PowerShell:

| Perintah | Deskripsi |
| :--- | :--- |
| `klipah start` | **Menyalakan** Klipah. UI Panel web akan terbuka di `localhost:8000`. |
| `klipah stop` | **Mematikan** sistem Klipah secara paksa. |
| `klipah status` | Mengecek log aktif dari background sistem. |
| `klipah token <token>` | **Memasukkan/Memperbarui Lisensi Anda**. |
| `klipah version` | Cek versi Engine terinstal. |
| `klipah uninstall` | Menghapus aplikasi secara total dari memori pengguna. |

---

## ✨ Upgrading / Restoration (Perpanjang Lisensi)

Jika Token lama Anda telah **Expired**, sistem pengaman *Self-Destruct* akan membekukan file sistem dan Klipah tidak bisa lagi digunakan.

Untuk membuka dan memulihkan kembali sistem Anda, tidak perlu melakukan instalasi ulang dari awal. Anda cukup meminta *Token* baru kepada Admin, lalu jalankan satu perintah ini di CMD/PowerShell:

```powershell
klipah token <TOKEN_BARU_ANDA>
```

Sistem akan otomatis memvalidasi token tersebut, mendownload ulang *core engine* yang membeku, dan Klipah siap digunakan kembali menggunakan `klipah start`.
