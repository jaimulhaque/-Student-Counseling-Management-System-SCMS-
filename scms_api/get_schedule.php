<?php
ob_start();
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { ob_end_clean(); http_response_code(200); exit; }

require_once 'db.php';

$counselor_id = isset($_GET['counselor_id']) ? intval($_GET['counselor_id']) : 0;

if ($counselor_id <= 0) {
    ob_end_clean();
    echo json_encode(['success' => false, 'message' => 'Invalid counselor_id', 'slots' => []]);
    exit;
}

// Safe: check if room_number column exists
$cols = $conn->query("SHOW COLUMNS FROM counselor_schedule_slots LIKE 'room_number'");
$hasRoomNumber = ($cols && $cols->num_rows > 0);
$roomSelect = $hasRoomNumber ? "IFNULL(room_number, '') AS room_number" : "'' AS room_number";

$stmt = $conn->prepare(
    "SELECT id, counselor_id, day,
            TIME_FORMAT(start_time, '%H:%i') AS start_time,
            TIME_FORMAT(end_time,   '%H:%i') AS end_time,
            $roomSelect
     FROM counselor_schedule_slots
     WHERE counselor_id = ?
     ORDER BY FIELD(day,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'), start_time"
);
$stmt->bind_param("i", $counselor_id);
$stmt->execute();
$result = $stmt->get_result();

$slots = [];
while ($row = $result->fetch_assoc()) {
    $slots[] = $row;
}

ob_end_clean();
echo json_encode(['success' => true, 'slots' => $slots]);
$conn->close();
?>
