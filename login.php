<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') { exit; }

include "koneksi.php";
include "log_helper.php";        // Fitur 1
include "rate_limit_helper.php"; // Fitur 3

$data = json_decode(file_get_contents("php://input"), true);
$identifier = $data["identifier"] ?? ''; 
$password   = $data["password"] ?? '';
$ip_address = $_SERVER['REMOTE_ADDR']; 

// --- [FITUR 3] CEK DULU APAKAH IP DIBLOKIR? ---
$status_blokir = check_rate_limit($pdo, $ip_address);
if ($status_blokir !== "aman") {
    echo json_encode(["status" => false, "message" => $status_blokir]);
    exit();
}
// ----------------------------------------------

try {
    // [FITUR 4] PENTING: Jangan cek password di SQL!
    // Ambil data user termasuk password-nya (baik itu teks biasa atau hash)
    $sql = "SELECT id, name, email, role, points, password FROM users WHERE (email = ? OR name = ?) LIMIT 1";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$identifier, $identifier]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    $login_success = false;

    if ($user) {
        $db_password = $user['password']; // Password dari database

        // SKENARIO A: Password di DB masih Teks Biasa (User Lama)
        // Kita cek manual string vs string
        if ($password === $db_password) {
            $login_success = true;
            
            // [AUTO-HASHING] Karena password masih tidak aman, kita enkripsi sekarang!
            // Menggunakan algoritma BCRYPT (Standar Keamanan Industri)
            $new_hash = password_hash($password, PASSWORD_DEFAULT);
            
            // Update password di database jadi hash
            $updPass = $pdo->prepare("UPDATE users SET password = ? WHERE id = ?");
            $updPass->execute([$new_hash, $user['id']]);
        } 
        
        // SKENARIO B: Password di DB sudah Ter-Enkripsi/Hash (User Aman)
        // Kita gunakan fungsi bawaan PHP untuk mengecek hash
        else if (password_verify($password, $db_password)) {
            $login_success = true;
        }
    }

    if ($login_success) {
        // === LOGIN BERHASIL ===

        // [FITUR 3] Reset Dosa (Hapus catatan gagal)
        reset_rate_limit($pdo, $ip_address);

        // [FITUR 2] Simpan IP & HP untuk Session Hijacking
        $user_agent = $_SERVER['HTTP_USER_AGENT']; 
        $upd = $pdo->prepare("UPDATE users SET last_login_ip = ?, last_user_agent = ? WHERE id = ?");
        $upd->execute([$ip_address, $user_agent, $user['id']]);

        // [FITUR 1] Catat Log Aktivitas
        catat_log($pdo, $user['id'], "Login Berhasil");

        echo json_encode([
            "status" => true,
            "message" => "Login Berhasil",
            "user" => [
                "id"    => (int)$user["id"],   
                "name"  => $user["name"],
                "email" => $user["email"],
                "role"  => $user["role"],
                "points"=> (int)$user["points"] 
            ]
        ]);
    } else {
        // === LOGIN GAGAL ===
        
        // [FITUR 3] Catat Kegagalan Login
        record_failed_login($pdo, $ip_address);

        // Cek sisa kesempatan
        $stmtCheck = $pdo->prepare("SELECT attempts FROM login_attempts WHERE ip_address = ?");
        $stmtCheck->execute([$ip_address]);
        $failData = $stmtCheck->fetch();
        $attempts = $failData['attempts'] ?? 0;
        $sisa = 3 - $attempts;

        $msg = "Email atau Password salah.";
        if ($sisa > 0) {
            $msg .= " Sisa percobaan: $sisa kali.";
        } else {
            $msg .= " Akun diblokir sementara (5 menit).";
        }

        echo json_encode(["status" => false, "message" => $msg]);
    }
} catch (PDOException $e) {
    echo json_encode(["status" => false, "message" => "Error: " . $e->getMessage()]);
}
?>