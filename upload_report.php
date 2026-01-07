<?php
// Matikan error warning HTML agar tidak merusak format JSON
error_reporting(0);
ini_set('display_errors', 0);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit;
}

include 'koneksi.php';
include 'log_helper.php'; // [PENTING] Untuk Audit Trail

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $user_id     = $_POST['user_id'] ?? null;
    $description = $_POST['description'] ?? '';
    $weight      = $_POST['weight'] ?? '0';

    if (!$user_id) {
        echo json_encode([
            "status" => false,
            "message" => "Error: User ID tidak ditemukan. Silakan login ulang."
        ]);
        exit;
    }

    if (isset($_FILES['image'])) {
        $files = $_FILES['image'];
        $uploaded_paths = array(); 
        $errors = array();

        if (!is_dir('uploads')) {
            mkdir('uploads', 0777, true);
        }

        // 1. UPLOAD FOTO
        foreach ($files['name'] as $key => $name) {
            if ($files['error'][$key] == 0) {
                $extension = pathinfo($name, PATHINFO_EXTENSION);
                $newName = "report_" . time() . "_" . uniqid() . "." . $extension;
                $targetPath = 'uploads/' . $newName;

                if (move_uploaded_file($files['tmp_name'][$key], $targetPath)) {
                    $uploaded_paths[] = $targetPath; 
                } else {
                    $errors[] = "Gagal memindahkan file: " . $name;
                }
            } else {
                $errors[] = "Error file $name kode: " . $files['error'][$key];
            }
        }

        // 2. INSERT KE DATABASE
        if (!empty($uploaded_paths)) {
            $image_url_string = implode(",", $uploaded_paths);

            try {
                $sql = "INSERT INTO reports (user_id, image_url, description, weight, latitude, longitude, status, created_at) 
                        VALUES (:user_id, :image_url, :description, :weight, :lat, :lng, 'pending', NOW())";
                
                $stmt = $pdo->prepare($sql);
                $saved = $stmt->execute([
                    ':user_id'     => $user_id,
                    ':image_url'   => $image_url_string,
                    ':description' => $description,
                    ':weight'      => $weight,
                    ':lat'         => '0.0',
                    ':lng'         => '0.0'
                ]);

                if ($saved) {
                    // [FITUR KEAMANAN] Catat Log Aktivitas
                    catat_log($pdo, $user_id, "Membuat Laporan Sampah ($weight Kg)");

                    $response['status'] = true;
                    $response['message'] = "Berhasil mengirim laporan dengan " . count($uploaded_paths) . " foto";
                }

            } catch (PDOException $e) {
                $response['status'] = false;
                $response['message'] = "DB Error: " . $e->getMessage();
            }
        } else {
            $response['status'] = false;
            $response['message'] = "Gagal mengunggah gambar apapun.";
            $response['debug_errors'] = $errors;
        }
    } else {
        $response['status'] = false;
        $response['message'] = "Tidak ada gambar yang dipilih.";
    }

    echo json_encode($response);
} else {
    echo json_encode(["status" => false, "message" => "Metode request tidak diizinkan"]);
}
?>