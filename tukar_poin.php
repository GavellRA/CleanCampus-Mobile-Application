<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') exit;

include "koneksi.php";
include "log_helper.php"; 
include "security_helper.php"; // [PENTING] Panggil Satpam

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['user_id'], $data['item_name'], $data['points_spent'])) {
    echo json_encode(["status" => "error", "message" => "Data tidak lengkap"]);
    exit;
}

$user_id = $data['user_id'];
$item_name = $data['item_name'];
$points_spent = (int)$data['points_spent'];

// --- [FITUR 2] CEK KEAMANAN SESI ---
$status_keamanan = cek_keamanan_sesi($pdo, $user_id);

if ($status_keamanan !== "aman") {
    // Jika tidak aman, batalkan proses dan kirim error
    echo json_encode(["status" => "error", "message" => $status_keamanan]);
    exit; 
}
// ------------------------------------

try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare("SELECT points FROM users WHERE id = ? FOR UPDATE");
    $stmt->execute([$user_id]);
    $user = $stmt->fetch();

    if (!$user || $user['points'] < $points_spent) {
        throw new Exception("Poin tidak cukup untuk menukar hadiah ini.");
    }

    $update = $pdo->prepare("UPDATE users SET points = points - ? WHERE id = ?");
    $update->execute([$points_spent, $user_id]);

    $insert = $pdo->prepare("INSERT INTO redemptions (user_id, item_name, points_spent, status) VALUES (?, ?, ?, 'pending')");
    $insert->execute([$user_id, $item_name, $points_spent]);

    catat_log($pdo, $user_id, "Menukar $points_spent Poin dengan $item_name");

    $pdo->commit();
    echo json_encode(["status" => "success", "message" => "Penukaran $item_name berhasil diproses!"]);

} catch (Exception $e) {
    $pdo->rollBack();
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>