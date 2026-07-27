<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$data         = json_decode(file_get_contents('php://input'), true) ?? [];
$user_id      = (int)($data['user_id']      ?? 0);
$old_password = $data['old_password'] ?? '';
$new_password = $data['new_password'] ?? '';

if ($user_id <= 0 || empty($old_password) || empty($new_password)) {
    ob_end_clean();
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Missing required fields"]);
    exit;
}

if (strlen($new_password) < 6) {
    ob_end_clean();
    echo json_encode(["success" => false, "message" => "New password must be at least 6 characters"]);
    exit;
}

$stmt = $conn->prepare("SELECT password FROM users WHERE id = ?");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$user = $stmt->get_result()->fetch_assoc();

if (!$user || !password_verify($old_password, $user['password'])) {
    ob_end_clean();
    http_response_code(401);
    echo json_encode(["success" => false, "message" => "Current password is incorrect"]);
    exit;
}

$hashed = password_hash($new_password, PASSWORD_DEFAULT);
$upd = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
$upd->bind_param("si", $hashed, $user_id);
$ok = $upd->execute();

ob_end_clean();
echo json_encode([
    "success" => $ok,
    "message" => $ok ? "Password changed successfully" : "Failed to change password"
]);
$conn->close();
?>
