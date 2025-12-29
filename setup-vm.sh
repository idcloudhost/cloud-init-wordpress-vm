#!/bin/bash

# --- VARIABLE SETUP ---
# Ganti URL ini dengan link Raw file 'stack-app.sh' milik Anda (GitHub Gist / GitHub Repo / lainnya)
# PENTING: Jika menggunakan GitHub Repo, pastikan klik tombol 'Raw' dan copy URL-nya.
# URL biasanya berawalan: https://raw.githubusercontent.com/  atau https://gist.githubusercontent.com/
URL_SCRIPT_APLIKASI="https://raw.githubusercontent.com/idcloudhost/cloud-init-wordpress-vm/refs/heads/master/stack-app.sh"

# Variable Dummy untuk Login Registry
# Ini mensimulasikan kebutuhan akses ke Private Docker Registry
REGISTRY_URL="registry.gitlab.com"
REG_USER="USER-DEMO"
REG_PASS="PASSWORD-DEMO-2025"

# --- STEP 1: INSTALL DOCKER ---
echo "[SETUP] Melakukan Instalasi Docker..."
echo "[INFO] Proses ini mungkin memakan waktu 1-2 menit..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Start Docker service if not already running
if ! docker info &> /dev/null; then
    echo "[INFO] Starting Docker service..."
    systemctl start docker || service docker start || true
    sleep 3
fi

# --- STEP 2: LOGIN PRIVATE REGISTRY ---
# Menggunakan --password-stdin agar password aman dan tidak terekam history shell
echo "[SETUP] Login ke Docker Registry..."
echo "$REG_PASS" | docker login "$REGISTRY_URL" -u "$REG_USER" --password-stdin || {
    echo "[WARNING] Docker registry login failed, continuing anyway..."
}

# --- STEP 3: DOWNLOAD SCRIPT APLIKASI ---
echo "[SETUP] Mendownload Script Aplikasi dari External Source..."
echo "[INFO] URL: $URL_SCRIPT_APLIKASI"
# Menggunakan flag -L untuk mengikuti redirect (penting untuk link Gist/Short URL)
curl -L -f $URL_SCRIPT_APLIKASI -o /root/stack-app.sh || {
    echo "[ERROR] Failed to download application script!"
    exit 1
}
chmod +x /root/stack-app.sh
echo "[SUCCESS] Script downloaded and made executable"

# --- STEP 4: EKSEKUSI CONTAINER ---
echo "[SETUP] Menjalankan Stack Aplikasi..."
echo "[INFO] Proses deployment container akan dimulai..."
echo "[INFO] Ini akan memakan waktu beberapa menit untuk download images dan setup container..."
echo ""
/root/stack-app.sh

echo ""
echo "[SETUP] Setup VM selesai!"
echo "[INFO] Silakan tunggu beberapa menit lagi untuk WordPress siap digunakan."
