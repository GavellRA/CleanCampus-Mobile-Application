<?php
// Matikan error HTML
error_reporting(0);
ini_set('display_errors', 0);

header('Content-Type: application/json');

include 'koneksi.php';    // Panggil koneksi database ($pdo)
include 'log_helper.php'; // [PENTING] Panggil helper untuk mencatat log

$user_id = $_POST['user_id'];
$message = $_POST['message'];
$sender  = $_POST['sender'];

if ($user_id && $message && $sender) {
    try {
        // QUERY PDO INSERT
        $sql = "INSERT INTO tb_chat (user_id, sender, message) VALUES (:uid, :snd, :msg)";
        $stmt = $pdo->prepare($sql);
        
        // Eksekusi dengan array parameter
        $saved = $stmt->execute([
            ':uid' => $user_id,
            ':snd' => $sender,
            ':msg' => $message
        ]);

        if ($saved) {
            // [FITUR KEAMANAN] Catat Log Aktivitas
            // Kita cek siapa pengirimnya agar log-nya rapi
            $aksi = ($sender == 'admin') ? "Admin Membalas Chat" : "Mengirim Pesan Chat";
            catat_log($pdo, $user_id, $aksi);

            echo json_encode(["status" => "success", "message" => "Pesan terkirim"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Gagal menyimpan"]);
        }
    } catch (PDOException $e) {
        echo json_encode(["status" => "error", "message" => "Database Error: " . $e->getMessage()]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Data tidak lengkap"]);
}
?>