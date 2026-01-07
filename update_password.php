<?php
// update_password.php
// Pastikan koneksi.php kamu sudah yang versi PDO (yang terakhir kita perbaiki)
include 'koneksi.php'; 

header("Content-Type: application/json");

$input = file_get_contents("php://input");
$data = json_decode($input);

if (!isset($data->email) || !isset($data->new_password)) {
    echo json_encode(["status" => false, "message" => "Data tidak lengkap"]);
    exit();
}

$email = $data->email;
$new_pass = $data->new_password;

try {
    // Cek dulu apakah email ada?
    $cek = $pdo->prepare("SELECT id FROM users WHERE email = ?");
    $cek->execute([$email]);
    
    if ($cek->rowCount() == 0) {
        echo json_encode(["status" => false, "message" => "Email tidak terdaftar!"]);
        exit();
    }

    // Update password (langsung update text biasa, karena login kamu belum pakai hash)
    $sql = "UPDATE users SET password = ? WHERE email = ?";
    $stmt = $pdo->prepare($sql);
    
    if ($stmt->execute([$new_pass, $email])) {
        echo json_encode(["status" => true, "message" => "Password berhasil diubah"]);
    } else {
        echo json_encode(["status" => false, "message" => "Gagal update database"]);
    }

} catch (PDOException $e) {
    echo json_encode(["status" => false, "message" => "Error DB: " . $e->getMessage()]);
}
?>