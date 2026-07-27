<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$user_id = (int)($_GET['user_id'] ?? 0);

if ($user_id <= 0) {
    ob_end_clean();
    echo json_encode(['success' => false, 'notifications' => []]);
    exit;
}

// Fetch unread notifications for this user
$stmt = $conn->prepare(
    "SELECT n.id, n.title, n.message, n.type, n.is_read, n.created_at,
            u.name AS sender_name
     FROM notifications n
     LEFT JOIN users u ON n.sender_id = u.id
     WHERE n.user_id = ?
     ORDER BY n.created_at DESC
     LIMIT 50"
);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$notifications = [];
while ($row = $result->fetch_assoc()) {
    $notifications[] = $row;
}

ob_end_clean();
echo json_encode(['success' => true, 'notifications' => $notifications]);
$conn->close();
?>
