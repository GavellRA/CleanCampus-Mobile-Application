<?php
// rate_limit_helper.php

function check_rate_limit($pdo, $ip_address) {
    // ATURAN: Maksimal 3x salah, Blokir 5 menit (300 detik)
    $max_attempts = 3;
    $lockout_time = 300; 

    $stmt = $pdo->prepare("SELECT attempts, last_attempt FROM login_attempts WHERE ip_address = ?");
    $stmt->execute([$ip_address]);
    $data = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($data) {
        $attempts = $data['attempts'];
        $last_attempt = strtotime($data['last_attempt']);
        $current_time = time(); // Waktu PHP sekarang
        
        // Hitung selisih waktu
        $time_diff = $current_time - $last_attempt;

        // Jika waktu database lebih "maju" dari PHP (kasus 365 menit), anggap selisih 0
        if ($time_diff < 0) $time_diff = 0;

        if ($attempts >= $max_attempts) {
            if ($time_diff < $lockout_time) {
                // Masih dalam masa hukuman
                $sisa_waktu = ceil(($lockout_time - $time_diff) / 60); 
                return "TERBLOKIR: Terlalu banyak percobaan gagal. Silakan tunggu $sisa_waktu menit lagi.";
            } else {
                // Hukuman selesai
                reset_rate_limit($pdo, $ip_address);
                return "aman";
            }
        }
    }
    return "aman";
}

function record_failed_login($pdo, $ip_address) {
    // [PERBAIKAN] Gunakan waktu PHP agar sinkron, jangan pakai NOW() MySQL
    $now = date('Y-m-d H:i:s'); 

    $sql = "INSERT INTO login_attempts (ip_address, attempts, last_attempt) 
            VALUES (?, 1, ?) 
            ON DUPLICATE KEY UPDATE attempts = attempts + 1, last_attempt = ?";
    $stmt = $pdo->prepare($sql);
    // Masukkan variabel $now ke dalam query
    $stmt->execute([$ip_address, $now, $now]);
}

function reset_rate_limit($pdo, $ip_address) {
    $stmt = $pdo->prepare("DELETE FROM login_attempts WHERE ip_address = ?");
    $stmt->execute([$ip_address]);
}
?>