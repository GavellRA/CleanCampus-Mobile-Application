<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
include "koneksi.php";

try {
    // Gabungkan tabel redemptions dengan users untuk mendapatkan nama user
    $sql = "SELECT r.*, u.name as user_name FROM redemptions r 
            JOIN users u ON r.user_id = u.id 
            ORDER BY r.created_at DESC";
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode($data);
} catch (PDOException $e) {
    echo json_encode([]);
}
?>