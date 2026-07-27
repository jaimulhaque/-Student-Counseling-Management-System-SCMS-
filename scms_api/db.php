<?php
$host   = "localhost";
$dbname = "scms";
$user   = "root";
$pass   = "";   // change if you set a password

$conn = new mysqli($host, $user, $pass, $dbname);

if ($conn->connect_error) {
    ob_end_clean();
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Database connection failed: " . $conn->connect_error
    ]);
    exit;
}

$conn->set_charset("utf8mb4");
?>
