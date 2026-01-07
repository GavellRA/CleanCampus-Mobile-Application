<?php
error_reporting(0);
ini_set('display_errors', 0);
header('Content-Type: application/json');
include 'koneksi.php';

try {
    // Join dengan tabel users supaya muncul Nama User, bukan cuma ID
    $sql = "SELECT l.*, u.name as user_name 
            FROM tb_logs l 
            JOIN users u ON l.user_id = u.id 
            ORDER BY l.created_at DESC LIMIT 50";
            
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $logs = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(["status" => "success", "data" => $logs]);
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "data" => []]);
}
?>