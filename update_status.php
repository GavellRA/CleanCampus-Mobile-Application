<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit;
}

include 'koneksi.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Menggunakan $_POST karena Flutter biasanya mengirim Map body
    $id = $_POST['id'] ?? null;
    $status = $_POST['status'] ?? null; 

    if (!$id || !$status) {
        echo json_encode(["success" => false, "error" => "ID atau Status kosong"]);
        exit;
    }

    try {
        $pdo->beginTransaction();

        $checkOld = $pdo->prepare("SELECT status, user_id, weight FROM reports WHERE id = ?");
        $checkOld->execute([$id]);
        $oldData = $checkOld->fetch(PDO::FETCH_ASSOC);

        if (!$oldData) {
            throw new Exception("Laporan tidak ditemukan");
        }

        // 1. Update status
        $sql = "UPDATE reports SET status = ? WHERE id = ?";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$status, $id]);

        // 2. Logika poin (Hanya jika status berubah jadi verified)
        if ($status == 'verified' && $oldData['status'] !== 'verified') {
            $user_id = $oldData['user_id'];
            $berat = (float)$oldData['weight'];
            $poin_didapat = $berat * 1000; 

            // UPDATE SALDO USER
            $stmtUser = $pdo->prepare("UPDATE users SET points = points + ? WHERE id = ?");
            $stmtUser->execute([$poin_didapat, $user_id]);

            // CATAT RIWAYAT POIN
            $stmtLog = $pdo->prepare("INSERT INTO points (user_id, type, amount, source, reference_id, created_at) 
                                     VALUES (?, 'in', ?, 'laporan_sampah', ?, NOW())");
            $stmtLog->execute([$user_id, $poin_didapat, $id]);
        }

        $pdo->commit();
        echo json_encode(["success" => true, "message" => "Berhasil memperbarui status"]);

    } catch (Exception $e) {
        $pdo->rollBack();
        echo json_encode(["success" => false, "error" => $e->getMessage()]);
    }
}
?>