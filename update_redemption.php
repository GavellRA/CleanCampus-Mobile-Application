<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
include "koneksi.php";

$id = $_POST['id'] ?? '';
$status = $_POST['status'] ?? ''; // Biasanya 'completed'

if (!$id || !$status) {
    echo json_encode(["status" => "error", "message" => "ID atau Status hilang"]);
    exit;
}

try {
    $sql = "UPDATE redemptions SET status = ? WHERE id = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$status, $id]);

    echo json_encode(["status" => "success"]);
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>