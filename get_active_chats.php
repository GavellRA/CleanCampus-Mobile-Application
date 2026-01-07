<?php
// get_active_chats.php
error_reporting(0);
ini_set('display_errors', 0);
header('Content-Type: application/json');
include 'koneksi.php';

try {
    // Query ini mengambil ID user yang ada di tabel chat
    // GANTI 'users' dengan nama tabel user kamu (misal: tb_users atau users)
    // Asumsi tabel user punya kolom: id, name, email
    $sql = "SELECT DISTINCT c.user_id, u.name, u.email 
            FROM tb_chat c 
            JOIN users u ON c.user_id = u.id 
            ORDER BY c.created_at DESC";
            
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(["status" => "success", "data" => $users]);
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>