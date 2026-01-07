<?php
// 1. Matikan error HTML agar JSON tidak rusak (PENTING)
error_reporting(0);
ini_set('display_errors', 0);

// 2. Set header agar Flutter tahu ini JSON
header('Content-Type: application/json');

include 'koneksi.php';

// Pastikan variabel koneksi ($koneksi) ada
if (!isset($pdo)) {
    echo json_encode(["status" => "error", "message" => "Variabel koneksi tidak ditemukan"]);
    exit();
}

$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : '';

if (!empty($user_id)) {
    try {
        // QUERY PDO
        $sql = "SELECT * FROM tb_chat WHERE user_id = :user_id ORDER BY created_at ASC";
        $stmt = $pdo->prepare($sql);
        
        // Binding parameter (mencegah SQL Injection)
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        // Ambil data sebagai Associative Array
        $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode(["status" => "success", "data" => $messages]);
        
    } catch (PDOException $e) {
        // Jika error database, kirim JSON error (bukan HTML)
        echo json_encode(["status" => "error", "message" => "Database Error: " . $e->getMessage()]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "User ID diperlukan"]);
}
?>