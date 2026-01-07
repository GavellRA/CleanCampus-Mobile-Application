<?php
// Matikan error warning HTML agar tidak merusak format JSON
error_reporting(0);
ini_set('display_errors', 0);

include 'koneksi.php'; // Ini akan memanggil variabel $pdo dari koneksi.php

header("Content-Type: application/json");

// Terima data JSON dari Flutter
$input = file_get_contents("php://input");
$data = json_decode($input);

// Validasi Input
if (!isset($data->email) || !isset($data->nama)) {
    echo json_encode(["status" => false, "message" => "Data tidak lengkap"]);
    exit();
}

$email = $data->email;
$nama = $data->nama;
$role = "user";

try {
    // 1. Cek apakah user sudah ada (Menggunakan Prepared Statement PDO)
    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch(); // Ambil satu baris data

    if ($user) {
        // KASUS A: User Lama -> Login Berhasil
        echo json_encode([
            "status" => true, 
            "message" => "Login Berhasil", 
            "user" => $user
        ]);
    } else {
        // KASUS B: User Baru -> Register Otomatis
        $sql = "INSERT INTO users (name, email, password, role) VALUES (?, ?, NULL, ?)";
        $stmt = $pdo->prepare($sql);
        
        if ($stmt->execute([$nama, $email, $role])) {
            // Ambil ID terakhir yang baru dibuat
            $id_baru = $pdo->lastInsertId();
            
            $user_baru = [
                "id" => $id_baru,
                "name" => $nama,
                "email" => $email,
                "role" => $role
            ];
            
            echo json_encode([
                "status" => true, 
                "message" => "Register Berhasil", 
                "user" => $user_baru
            ]);
        } else {
            echo json_encode(["status" => false, "message" => "Gagal Register Database"]);
        }
    }
} catch (Exception $e) {
    // Tangkap error jika query gagal
    echo json_encode(["status" => false, "message" => "Error Server: " . $e->getMessage()]);
}
?>