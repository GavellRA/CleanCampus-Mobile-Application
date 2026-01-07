<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit;
}

include "koneksi.php";
include "log_helper.php"; // [FITUR 1] Audit Trail

$data = json_decode(file_get_contents("php://input"), true);

$name     = $data["name"] ?? ''; 
$email    = $data["email"] ?? '';
$password = $data["password"] ?? '';

if (empty($name) || empty($email) || empty($password)) {
    echo json_encode(["status" => false, "message" => "Data tidak lengkap"]);
    exit;
}

try {
    // 1. Cek Duplikasi
    $stmtCek = $pdo->prepare("SELECT id FROM users WHERE email = ? OR name = ?");
    $stmtCek->execute([$email, $name]);
    
    if ($stmtCek->rowCount() > 0) {
        echo json_encode(["status" => false, "message" => "Email atau Username sudah digunakan"]);
    } else {
        
        // [FITUR 4] ENKRIPSI PASSWORD SEJAK AWAL
        // Kita tidak simpan $password mentah, tapi yang sudah di-hash
        $hashed_password = password_hash($password, PASSWORD_DEFAULT);

        // 2. Simpan ke Database (Password Aman)
        $stmtInsert = $pdo->prepare("INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, 'user')");
        $success = $stmtInsert->execute([$name, $email, $hashed_password]);

        if ($success) {
            // Ambil ID user yang barusan dibuat untuk keperluan Log
            $new_user_id = $pdo->lastInsertId();

            // [FITUR 1] Catat Log Pendaftaran
            catat_log($pdo, $new_user_id, "Register Akun Baru");

            echo json_encode(["status" => true, "message" => "Register berhasil"]);
        } else {
            echo json_encode(["status" => false, "message" => "Gagal menyimpan data"]);
        }
    }
} catch (PDOException $e) {
    echo json_encode(["status" => false, "message" => "Error Server: " . $e->getMessage()]);
}
?>