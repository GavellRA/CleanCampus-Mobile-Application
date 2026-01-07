<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
include "koneksi.php";

$user_id = $_GET['id'];

try {
    // Ambil data poin terbaru langsung dari tabel users
    $sql = "SELECT points FROM users WHERE id = :id";
    $stmt = $pdo->prepare($sql);
    $stmt->execute(['id' => $user_id]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        echo json_encode([
            "status" => "success",
            "points" => $user['points']
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => "User tidak ditemukan"]);
    }
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>