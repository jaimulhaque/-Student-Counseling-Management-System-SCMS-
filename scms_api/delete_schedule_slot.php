<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$data    = json_decode(file_get_contents("php://input"), true);
$slot_id = isset($data['slot_id']) ? intval($data['slot_id']) : 0;

if ($slot_id <= 0) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'Invalid slot_id']);
    exit;
}

$today = date('Y-m-d');
$check = $conn->prepare(
    "SELECT id FROM appointments WHERE slot_id = ? AND date >= ? AND status = 'booked' LIMIT 1"
);
$check->bind_param("is", $slot_id, $today);
$check->execute();
$check->store_result();
if ($check->num_rows > 0) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'Cannot delete — there are upcoming bookings for this slot.']);
    exit;
}
$check->close();

$stmt = $conn->prepare("DELETE FROM counselor_schedule_slots WHERE id = ?");
$stmt->bind_param("i", $slot_id);

ob_end_clean();
if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Slot deleted']);
} else {
    echo json_encode(['success' => false, 'message' => 'Delete failed: ' . $stmt->error]);
}
$conn->close();
?>