<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

header('Content-Type: application/json');
include 'koneksi.php';

// Validasi apakah user_id dikirim
if (!isset($_GET['user_id'])) {
    echo json_encode(["status" => "error", "message" => "Parameter user_id hilang"]);
    exit;
}

$user_id = $_GET['user_id'];

try {
    // 1. Ambil Data Lengkap User (Points, Name, Email, Phone, Role)
    // PERUBAHAN DI SINI: Menambahkan email dan phone ke dalam SELECT
    $stmt1 = $pdo->prepare("SELECT points, name, email, phone, role FROM users WHERE id = ?");
    $stmt1->execute([$user_id]);
    $user = $stmt1->fetch(PDO::FETCH_ASSOC);

    // Jika user tidak ditemukan
    if (!$user) {
        echo json_encode(["status" => "error", "message" => "User tidak ditemukan"]);
        exit;
    }

    // 2. Hitung Jumlah Laporan yang HANYA berstatus 'verified'
    $stmt2 = $pdo->prepare("SELECT COUNT(*) as total_verified FROM reports WHERE user_id = ? AND status = 'verified'");
    $stmt2->execute([$user_id]);
    $report = $stmt2->fetch(PDO::FETCH_ASSOC);

    // Kirim respons JSON
    echo json_encode([
        "status" => "success",
        "name" => $user['name'],
        "email" => $user['email'],      // Dikirim ke Flutter
        "phone" => $user['phone'] ?? "", // Dikirim ke Flutter (jika null, kirim string kosong)
        "role" => $user['role'],        // Dikirim jaga-jaga jika butuh cek role
        "points" => (int)$user['points'], 
        "total_laporan" => (int)$report['total_verified']
    ]);

} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>