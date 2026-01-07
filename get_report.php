<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit;
}

include 'koneksi.php';

$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;
// Ambil status dari URL, jika tidak ada set default ke 'semua'
$status = isset($_GET['status']) ? $_GET['status'] : 'semua';

if (!$user_id) {
    echo json_encode(["error" => "User ID diperlukan"]);
    exit;
}

try {
    // Logika Filter
    if ($status == 'semua') {
        $sql = "SELECT * FROM reports WHERE user_id = :user_id ORDER BY created_at DESC";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':user_id' => $user_id]);
    } else {
        $sql = "SELECT * FROM reports WHERE user_id = :user_id AND status = :status ORDER BY created_at DESC";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':user_id' => $user_id, ':status' => $status]);
    }
    
    $reports = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($reports);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => $e->getMessage()]);
}
?>