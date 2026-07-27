<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$data    = json_decode(file_get_contents("php://input"), true) ?? [];
$user_id = (int)($data['user_id'] ?? 0);

if ($user_id <= 0) {
    ob_end_clean();
    echo json_encode(['success' => false]);
    exit;
}

$stmt = $conn->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ?");
$stmt->bind_param("i", $user_id);
$stmt->execute();

ob_end_clean();
echo json_encode(['success' => true]);
$conn->close();
?>
