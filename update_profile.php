<?php
// File: update_profile.php
include 'koneksi.php';

// Header agar bisa diakses dari HP/Emulator
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

// Menerima input JSON
$input = file_get_contents("php://input");
$data = json_decode($input);

// 1. Validasi Input: Pastikan 'phone' juga dicek
if (!isset($data->user_id) || !isset($data->nama) || !isset($data->email) || !isset($data->phone)) {
    echo json_encode([
        "status" => "error", 
        "message" => "Data tidak lengkap"
    ]);
    exit();
}

$user_id = $data->user_id;
$nama = $data->nama;
$email = $data->email;
$phone = $data->phone; // [BARU] Ambil data phone dari JSON

try {
    // 2. Query Update: Tambahkan kolom phone = ?
    $sql = "UPDATE users SET name = ?, email = ?, phone = ? WHERE id = ?";
    $stmt = $pdo->prepare($sql);
    
    // 3. Eksekusi: Masukkan variabel $phone ke dalam urutan array
    $execute = $stmt->execute([$nama, $email, $phone, $user_id]);

    if ($execute) {
        echo json_encode([
            "status" => "success", 
            "message" => "Profil berhasil diperbarui"
        ]);
    } else {
        echo json_encode([
            "status" => "error", 
            "message" => "Gagal memperbarui profil"
        ]);
    }
} catch (PDOException $e) {
    echo json_encode([
        "status" => "error", 
        "message" => "Database error: " . $e->getMessage()
    ]);
}
?>