<?php
// log_helper.php
function catat_log($pdo, $user_id, $action) {
    try {
        $ip = $_SERVER['REMOTE_ADDR']; // Ambil IP Pengguna
        
        $sql = "INSERT INTO tb_logs (user_id, action, ip_address) VALUES (:uid, :act, :ip)";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':uid' => $user_id,
            ':act' => $action,
            ':ip'  => $ip
        ]);
    } catch (Exception $e) {
        // Diam saja jika gagal mencatat log, jangan sampai mengganggu fungsi utama
    }
}
?>