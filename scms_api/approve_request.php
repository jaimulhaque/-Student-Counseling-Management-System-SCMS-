<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ob_end_clean(); http_response_code(405);
    echo json_encode(["success" => false, "message" => "Method not allowed"]); exit;
}

require_once 'db.php';

$data         = json_decode(file_get_contents("php://input"), true) ?? [];
$request_id   = (int)($data['request_id']   ?? 0);
$counselor_id = (int)($data['counselor_id'] ?? 0);

if ($request_id <= 0 || $counselor_id <= 0) {
    ob_end_clean();
    echo json_encode(["success" => false, "message" => "Invalid request or counselor ID"]); exit;
}

// Check request still pending
$check = $conn->prepare("SELECT id FROM counseling_requests WHERE id = ? AND status = 'pending'");
$check->bind_param("i", $request_id);
$check->execute();
$check->store_result();
if ($check->num_rows === 0) {
    ob_end_clean();
    echo json_encode(["success" => false, "message" => "Request not found or already processed"]); exit;
}
$check->close();

// Try to get a room — OPTIONAL, approval is NOT blocked if no rooms exist
$room_id = null;
$roomResult = $conn->query("SELECT id FROM rooms WHERE status = 'available' LIMIT 1");
if ($roomResult && $roomResult->num_rows > 0) {
    $room_id = (int)$roomResult->fetch_assoc()['id'];
}

// Use appointment_time from request if already set (booked via slot), else set to +1 hour
$timeRow = $conn->prepare("SELECT appointment_time FROM counseling_requests WHERE id = ?");
$timeRow->bind_param("i", $request_id);
$timeRow->execute();
$timeData = $timeRow->get_result()->fetch_assoc();
$apptTime = (!empty($timeData['appointment_time']))
    ? $timeData['appointment_time']
    : date('Y-m-d H:i:s', strtotime('+1 hour'));

// Approve
$stmt = $conn->prepare(
    "UPDATE counseling_requests 
     SET status = 'approved', counselor_id = ?, room_id = ?, appointment_time = ?
     WHERE id = ? AND status = 'pending'"
);
$stmt->bind_param("iiis", $counselor_id, $room_id, $apptTime, $request_id);
$ok = $stmt->execute();
$affected = $stmt->affected_rows;

if ($ok && $affected > 0 && $room_id) {
    $upd = $conn->prepare("UPDATE rooms SET status = 'occupied' WHERE id = ?");
    $upd->bind_param("i", $room_id);
    $upd->execute();
}

ob_end_clean();
echo json_encode([
    "success" => $ok && $affected > 0,
    "message" => ($ok && $affected > 0)
        ? "Request approved successfully"
        : "Failed to approve (already processed or invalid)"
]);
$conn->close();
?>