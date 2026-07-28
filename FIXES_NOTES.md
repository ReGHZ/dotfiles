# Dotfiles Fixes - Desktop vs Laptop Issues

## Ringkasan Masalah & Solusi

### ✅ Masalah 1: Waybar Berjalan 2x (Desktop Saja)

**Penyebab:**
- Race condition pada `pgrep -x waybar` check
- Antara pengecekan dan pelaksanaan `&` di latar belakang, ada celah waktu
- Di desktop dengan prosesor cepat, 2 instance mulai bersamaan
- Di laptop lebih lambat, prosesnya kehabisan waktu dan tertutup otomatis

**Solusi di [togglebar.sh](bin/.local/bin/togglebar.sh):**
```bash
# ❌ LAMA - Race condition:
if ! pgrep -x waybar > /dev/null; then
    waybar ... &
fi

# ✅ BARU - Lebih akurat + initial cleanup:
pkill -x waybar 2>/dev/null  # Cleanup di startup
sleep 0.5
if ! pgrep -f "waybar.*config.jsonc" > /dev/null 2>&1; then
    waybar ... &
    sleep 0.2
fi
```

---

### ✅ Masalah 2: eww Nyangkut di Background

**Penyebab:**
- Daemon eww terus berjalan meski window ditutup
- Tidak ada pengecekan status closure
- Timing issue antara close command dan process check

**Solusi di [togglebar.sh](bin/.local/bin/togglebar.sh):**
```bash
# ❌ LAMA - Tidak wait untuk close:
eww close sysinfo

# ✅ BARU - Dengan pengecekan dan delay:
if eww active-windows 2>/dev/null | grep -q sysinfo; then
    eww close sysinfo 2>/dev/null
    sleep 0.3  # Tunggu process selesai
fi
```

---

### ✅ Masalah 3: CPU & RAM Tidak Update Real-Time

**Penyebab:**
1. **Script `cpu-bar` bergantung pada `mpstat`** (dari paket sysstat)
   - Di beberapa instalasi CachyOS, paket ini tidak installed atau config berbeda
   - Sampel 1 detik + AWK parsing membuat output delay

2. **Script `mem-bar` pakai `free -m`** (cache reporting tidak akurat)
   - MemAvailable sebenarnya berbeda dengan calculation simple dari used/total

**Solusi:**

#### CPU Script - Gunakan `/proc/stat` langsung:
[eww/.config/eww/scripts/cpu-bar](eww/.config/eww/scripts/cpu-bar)
- Baca `/proc/stat` 2 kali dengan delay 0.5s
- Hitung delta untuk akurasi tinggi
- Tidak butuh external tool (mpstat)
- Responsif & reliabel di semua Arch variant

#### RAM Script - Gunakan `/proc/meminfo`:
[eww/.config/eww/scripts/mem-bar](eww/.config/eww/scripts/mem-bar)
- Ganti `free` command dengan read dari `/proc/meminfo`
- Pakai `MemAvailable` (kernel calculated) bukan simple math
- Akurat untuk available memory vs cached pages
- Lebih cepat parsing

---

## Testing

Setelah apply fixes, test dengan:

```bash
# 1. Cek togglebar logic (lihat process)
ps aux | grep -E "waybar|eww" | grep -v grep

# 2. Test script update rate - buka 10 terminal:
watch -n 0.1 ~/.config/eww/scripts/cpu-bar 0

# 3. Cek memory dari kedua sumber:
/proc/meminfo vs free -m
```

---

## Notes

- **Desktop vs Laptop:** Perbedaan observable karena timing berbeda, bukan config
- **Kompatibilitas:** Fixes pakai bash standard + `/proc` filesystem (semua Linux have)
- **Performance:** Update rate lebih baik, CPU usage lebih rendah (no external tool)
