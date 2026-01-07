<?php
// security_helper.php

function cek_keamanan_sesi($pdo, $user_id) {
    // 1. Ambil IP & HP Pengirim Request Saat Ini
    $current_ip = $_SERVER['REMOTE_ADDR'];
    $current_ua = $_SERVER['HTTP_USER_AGENT'];

    // 2. Ambil IP & HP yang TEREKAM di Database (Saat Login)
    $stmt = $pdo->prepare("SELECT last_login_ip, last_user_agent FROM users WHERE id = ?");
    $stmt->execute([$user_id]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        return "User tidak ditemukan";
    }

    // 3. BANDINGKAN!
    // Jika IP beda ATAU Tipe HP beda -> TOLAK
    if ($user['last_login_ip'] !== $current_ip || $user['last_user_agent'] !== $current_ua) {
        return "SESSION HIJACK DETECTED! IP Address berubah dari {$user['last_login_ip']} menjadi $current_ip. Akses ditolak.";
    }

    return "aman"; // Jika cocok
}
?>