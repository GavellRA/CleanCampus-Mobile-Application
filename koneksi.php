<?php
$host = "localhost";
$db   = "aplikasi_sampah";
$user = "root";
$pass = "";

try {
    // Membuat koneksi PDO
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8", $user, $pass);
    
    // Set mode error ke Exception agar mudah didebug
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Default fetch mode menjadi Associative Array
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

} catch (PDOException $e) {
    header('Content-Type: application/json');
    die(json_encode([
        "status" => false,
        "message" => "Koneksi database gagal: " . $e->getMessage()
    ]));
}
?>