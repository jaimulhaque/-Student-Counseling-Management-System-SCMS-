<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { ob_end_clean(); http_response_code(405); echo json_encode(["success"=>false,"message"=>"Method not allowed"]); exit; }

require_once 'db.php';

$data     = json_decode(file_get_contents('php://input'), true) ?? [];
$email    = trim($data['email']    ?? '');
$password = $data['password'] ?? '';

if (empty($email) || empty($password)) {
    ob_end_clean();
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Email and password required"]);
    exit;
}

$stmt = $conn->prepare("SELECT id, name, email, phone, role, department, student_id, intake, section, designation FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();

if (!$user) {
    ob_end_clean();
    http_response_code(401);
    echo json_encode(["success" => false, "message" => "Invalid email or password"]);
    exit;
}

// Get password separately
$pwStmt = $conn->prepare("SELECT password FROM users WHERE id = ?");
$pwStmt->bind_param("i", $user['id']);
$pwStmt->execute();
$pwRow = $pwStmt->get_result()->fetch_assoc();

if (!password_verify($password, $pwRow['password'])) {
    ob_end_clean();
    http_response_code(401);
    echo json_encode(["success" => false, "message" => "Invalid email or password"]);
    exit;
}

ob_end_clean();
http_response_code(200);
echo json_encode([
    "success" => true,
    "user"    => $user  // returns full user profile so app doesn't need extra API calls
]);
$conn->close();
?>
