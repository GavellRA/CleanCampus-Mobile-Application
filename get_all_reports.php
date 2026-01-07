<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

include 'koneksi.php';

try {
    // PERBAIKAN: Menggunakan 'u.name' sesuai dengan struktur login Anda
    $sql = "SELECT r.*, u.name as nama_user 
            FROM reports r 
            LEFT JOIN users u ON r.user_id = u.id 
            ORDER BY r.id DESC";
            
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Mengirimkan data kosong [] jika tidak ada laporan, bukan null
    echo json_encode($data ? $data : []);

} catch (PDOException $e) {
    // Jika ada error SQL, kirimkan status false agar Flutter berhenti loading
    http_response_code(500);
    echo json_encode([
        "status" => false, 
        "message" => "Database Error: " . $e->getMessage()
    ]);
}
?>