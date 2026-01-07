<?php
// check_email.php
include 'koneksi.php';
header("Content-Type: application/json");

// Matikan error HTML agar JSON tetap bersih
error_reporting(0);
ini_set('display_errors', 0);

$input = file_get_contents("php://input");
$data = json_decode($input);

if (!isset($data->email)) {
    echo json_encode(["status" => false, "message" => "Email kosong"]);
    exit();
}

$email = $data->email;

try {
    // Cek apakah email ada di database
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);

    if ($stmt->rowCount() > 0) {
        // Email DITEMUKAN (Boleh lanjut reset password)
        echo json_encode(["status" => true, "message" => "Email terdaftar"]);
    } else {
        // Email TIDAK DITEMUKAN (Tolak)
        echo json_encode(["status" => false, "message" => "Email tidak terdaftar"]);
    }
} catch (PDOException $e) {
    echo json_encode(["status" => false, "message" => "Error DB: " . $e->getMessage()]);
}
?>